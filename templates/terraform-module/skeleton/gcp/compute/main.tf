locals {
  # Resource names are limited to 63 characters and service account IDs to 30,
  # so the project name is shortened before the environment is appended.
  name_prefix = "${trimsuffix(substr(var.project_name, 0, 16), "-")}-${var.environment}"

  labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })

  # A null network selects the project's default (auto mode) network, whose
  # regional subnet is picked automatically when no subnet is named.
  network    = coalesce(var.network_name, "default")
  zones      = distinct(concat([var.zone], var.additional_zones))
  target_tag = "${local.name_prefix}-vm"

  startup_script = coalesce(var.startup_script, templatefile("${path.module}/templates/startup.sh", {
    project_name      = var.project_name
    environment       = var.environment
    app_port          = var.app_port
    health_check_path = coalesce(var.health_check_path, "/healthz")
  }))

  # Google front ends that proxy IAP TCP forwarding and load balancer health checks.
  iap_source_ranges          = ["35.235.240.0/20"]
  health_check_source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

# -----------------------------------------------------------------------------
# Instance identity
# -----------------------------------------------------------------------------

resource "google_service_account" "compute" {
  project      = var.project_id
  account_id   = "${local.name_prefix}-vm"
  display_name = "${var.project_name} ${var.environment} instances"
  description  = "Identity of the ${var.project_name} instance group in ${var.environment}"
}

resource "google_project_iam_member" "compute" {
  for_each = toset(var.service_account_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.compute.email}"
}

# -----------------------------------------------------------------------------
# Instance template
# -----------------------------------------------------------------------------

resource "google_compute_instance_template" "main" {
  project      = var.project_id
  region       = var.region
  name_prefix  = "${local.name_prefix}-"
  description  = "Instance template for ${var.project_name} (${var.environment})"
  machine_type = var.machine_type
  tags         = [local.target_tag]
  labels       = local.labels

  can_ip_forward = false

  disk {
    source_image = var.source_image
    disk_type    = var.boot_disk_type
    disk_size_gb = var.boot_disk_size_gb
    boot         = true
    auto_delete  = true
    labels       = local.labels

    dynamic "disk_encryption_key" {
      for_each = var.kms_key_id == null ? [] : [var.kms_key_id]

      content {
        kms_key_self_link = disk_encryption_key.value
      }
    }
  }

  dynamic "disk" {
    for_each = var.data_disk_size_gb > 0 ? [var.data_disk_size_gb] : []

    content {
      disk_type    = var.boot_disk_type
      disk_size_gb = disk.value
      device_name  = "data"
      boot         = false
      auto_delete  = true
      labels       = local.labels

      dynamic "disk_encryption_key" {
        for_each = var.kms_key_id == null ? [] : [var.kms_key_id]

        content {
          kms_key_self_link = disk_encryption_key.value
        }
      }
    }
  }

  # No access_config block: instances get no external address and reach the
  # internet through Cloud NAT.
  network_interface {
    network            = var.subnet_name == null ? local.network : null
    subnetwork         = var.subnet_name
    subnetwork_project = var.subnet_name == null ? null : var.project_id
  }

  service_account {
    email  = google_service_account.compute.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  scheduling {
    provisioning_model          = var.enable_spot ? "SPOT" : "STANDARD"
    preemptible                 = var.enable_spot
    automatic_restart           = !var.enable_spot
    on_host_maintenance         = var.enable_spot ? "TERMINATE" : "MIGRATE"
    instance_termination_action = var.enable_spot ? "STOP" : null
  }

  metadata = merge(var.metadata, {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "true"
    serial-port-enable     = "false"
    startup-script         = local.startup_script
  })

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Managed instance group
# -----------------------------------------------------------------------------

resource "google_compute_health_check" "main" {
  project             = var.project_id
  name                = "${local.name_prefix}-hc"
  description         = "Health check for the ${var.project_name} instance group (${var.environment})"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  dynamic "http_health_check" {
    for_each = var.health_check_path == null ? [] : [var.health_check_path]

    content {
      port         = var.app_port
      request_path = http_health_check.value
    }
  }

  dynamic "tcp_health_check" {
    for_each = var.health_check_path == null ? [1] : []

    content {
      port = var.app_port
    }
  }

  log_config {
    enable = true
  }
}

resource "google_compute_region_instance_group_manager" "main" {
  project                   = var.project_id
  region                    = var.region
  name                      = "${local.name_prefix}-mig"
  description               = "Managed instance group for ${var.project_name} (${var.environment})"
  base_instance_name        = local.name_prefix
  distribution_policy_zones = local.zones

  version {
    instance_template = google_compute_instance_template.main.self_link_unique
  }

  named_port {
    name = "http"
    port = var.app_port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.main.id
    initial_delay_sec = var.auto_healing_initial_delay_sec
  }

  # Regional groups require fixed surge values of zero or at least one per zone.
  update_policy {
    type                         = "PROACTIVE"
    minimal_action               = "REPLACE"
    instance_redistribution_type = "PROACTIVE"
    max_surge_fixed              = length(local.zones)
    max_unavailable_fixed        = 0
  }

  # The autoscaler owns the group size.
  lifecycle {
    ignore_changes = [target_size]
  }
}

resource "google_compute_region_autoscaler" "main" {
  project = var.project_id
  region  = var.region
  name    = "${local.name_prefix}-autoscaler"
  target  = google_compute_region_instance_group_manager.main.id

  autoscaling_policy {
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    cooldown_period = var.autoscaler_cooldown_period

    cpu_utilization {
      target = var.target_cpu_utilization
    }
  }

  lifecycle {
    precondition {
      condition     = var.max_replicas >= var.min_replicas
      error_message = "max_replicas must be greater than or equal to min_replicas."
    }
  }
}

# -----------------------------------------------------------------------------
# Firewall rules scoped to the group's network tag
# -----------------------------------------------------------------------------

resource "google_compute_firewall" "health_check" {
  project       = var.project_id
  name          = "${local.name_prefix}-vm-health-check"
  description   = "Allow Google Cloud health check probes to reach the instance group"
  network       = local.network
  direction     = "INGRESS"
  source_ranges = local.health_check_source_ranges
  target_tags   = [local.target_tag]

  allow {
    protocol = "tcp"
    ports    = [tostring(var.app_port)]
  }
}

resource "google_compute_firewall" "iap_ssh" {
  count = var.enable_iap_ssh ? 1 : 0

  project       = var.project_id
  name          = "${local.name_prefix}-vm-iap-ssh"
  description   = "Allow SSH to the instance group through Identity-Aware Proxy"
  network       = local.network
  direction     = "INGRESS"
  source_ranges = local.iap_source_ranges
  target_tags   = [local.target_tag]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "app" {
  count = length(var.app_source_ranges) > 0 ? 1 : 0

  project       = var.project_id
  name          = "${local.name_prefix}-vm-app"
  description   = "Allow the configured ranges to reach the application port"
  network       = local.network
  direction     = "INGRESS"
  source_ranges = var.app_source_ranges
  target_tags   = [local.target_tag]

  allow {
    protocol = "tcp"
    ports    = [tostring(var.app_port)]
  }
}
