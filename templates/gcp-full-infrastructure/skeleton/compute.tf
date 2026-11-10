# =============================================================================
# Compute: instance template and regional managed instance group
# =============================================================================

resource "google_service_account" "compute" {
  count = var.enable_compute ? 1 : 0

  account_id   = "${local.sa_prefix}-vm"
  display_name = "Compute Engine instances of ${local.name_prefix}"

  depends_on = [google_project_service.main]
}

resource "google_project_iam_member" "compute" {
  for_each = var.enable_compute ? toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ]) : toset([])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.compute[0].email}"
}

resource "google_compute_instance_template" "main" {
  count = var.enable_compute ? 1 : 0

  name_prefix  = "${local.name_prefix}-"
  description  = "Instance template of ${var.project_name} (${var.environment})"
  machine_type = var.machine_type
  region       = var.region
  labels       = local.labels

  disk {
    source_image = var.instance_image
    disk_size_gb = var.boot_disk_size
    disk_type    = var.boot_disk_type
    boot         = true
    auto_delete  = true
  }

  # No access_config block: instances have no public address and reach the
  # internet through Cloud NAT.
  network_interface {
    network    = local.network_id
    subnetwork = local.subnetwork_id
  }

  can_ip_forward = false

  metadata = {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "TRUE"
    serial-port-enable     = "FALSE"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  service_account {
    email  = google_service_account.compute[0].email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "main" {
  count = var.enable_compute ? 1 : 0

  name               = "${local.name_prefix}-mig"
  description        = "Managed instance group of ${var.project_name} (${var.environment})"
  region             = var.region
  base_instance_name = local.name_prefix
  target_size        = var.instance_count

  version {
    instance_template = google_compute_instance_template.main[0].id
  }

  update_policy {
    type                         = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 3
    max_unavailable_fixed        = 0
    instance_redistribution_type = "PROACTIVE"
  }
}
