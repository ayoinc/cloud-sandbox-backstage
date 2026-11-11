# -----------------------------------------------------------------------------
# Virtual machine: Compute Engine instance without an external IP address,
# reached through Identity-Aware Proxy, stopped on a schedule outside
# production
# -----------------------------------------------------------------------------

variable "vm_machine_type" {
  description = "Machine type of the virtual machine."
  type        = string
  default     = "e2-micro"
}

variable "auto_shutdown_schedule" {
  description = "Cron expression (minute hour * * weekdays, UTC) at which the virtual machine is stopped outside production. Null disables it."
  type        = string
  default     = null

  validation {
    condition     = var.auto_shutdown_schedule == null || can(regex("^[0-5]?[0-9] ([01]?[0-9]|2[0-3]) \\* \\* (\\*|[0-6](-[0-6])?(,[0-6](-[0-6])?)*)$", var.auto_shutdown_schedule))
    error_message = "auto_shutdown_schedule must be a cron expression of the form \"minute hour * * weekdays\", for example \"0 19 * * 1-5\"."
  }
}

locals {
  vm_auto_shutdown_enabled = var.environment != "production" && var.auto_shutdown_schedule != null

  project_number = var.create_resource_container ? google_project.this[0].number : data.google_project.existing[0].number
}

data "google_compute_zones" "available" {
  project = local.project_id
  region  = var.region
  status  = "UP"

  depends_on = [google_project_service.compute]
}

resource "google_service_account" "vm" {
  project      = local.project_id
  account_id   = "${substr(var.component_name, 0, 24)}-vm"
  display_name = "Virtual machine of the ${var.component_name} component"
}

# 35.235.240.0/20 is the range Identity-Aware Proxy forwards TCP from, so SSH
# is open to authenticated IAP users only.
resource "google_compute_firewall" "vm_iap_ssh" {
  project     = local.project_id
  name        = "${module.naming.standard["vm"]}-allow-iap-ssh"
  network     = google_compute_network.this.id
  description = "SSH to the virtual machine through Identity-Aware Proxy"
  direction   = "INGRESS"

  source_ranges           = ["35.235.240.0/20"]
  target_service_accounts = [google_service_account.vm.email]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# Compute Engine stops the machine on the schedule; its service agent needs
# permission to do so.
resource "google_project_iam_member" "vm_schedule" {
  count = local.vm_auto_shutdown_enabled ? 1 : 0

  project = local.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:service-${local.project_number}@compute-system.iam.gserviceaccount.com"

  depends_on = [google_project_service.compute]
}

resource "google_compute_resource_policy" "vm_shutdown" {
  count = local.vm_auto_shutdown_enabled ? 1 : 0

  project     = local.project_id
  name        = "${module.naming.standard["vm"]}-shutdown"
  region      = var.region
  description = "Stops the ${var.component_name} virtual machine"

  instance_schedule_policy {
    time_zone = "UTC"

    vm_stop_schedule {
      schedule = var.auto_shutdown_schedule
    }
  }

  depends_on = [google_project_iam_member.vm_schedule]
}

resource "google_compute_instance" "this" {
  project      = local.project_id
  name         = module.naming.standard["vm"]
  zone         = data.google_compute_zones.available.names[0]
  machine_type = var.vm_machine_type

  resource_policies = google_compute_resource_policy.vm_shutdown[*].id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  # No access_config block: the machine has no external IP address.
  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  metadata = {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "TRUE"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  service_account {
    email  = google_service_account.vm.email
    scopes = ["cloud-platform"]
  }

  # A newer image must not replace a running machine on the next apply.
  lifecycle {
    ignore_changes = [boot_disk[0].initialize_params[0].image]
  }
}

output "vm_name" {
  description = "Name of the virtual machine, for `gcloud compute ssh --tunnel-through-iap`."
  value       = google_compute_instance.this.name
}

output "vm_zone" {
  description = "Zone of the virtual machine."
  value       = google_compute_instance.this.zone
}
