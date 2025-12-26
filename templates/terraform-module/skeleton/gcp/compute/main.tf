# -----------------------------------------------------------------------------
# GCP Compute Module - Main Resources
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_id}-${var.environment}"

  default_labels = {
    project     = var.project_id
    environment = var.environment
    managed_by  = "terraform"
  }

  labels = merge(local.default_labels, var.labels)
}

# -----------------------------------------------------------------------------
# Service Account for Compute Instances
# -----------------------------------------------------------------------------

resource "google_service_account" "compute" {
  account_id   = "${local.name_prefix}-compute-sa"
  display_name = "Service account for ${local.name_prefix} compute instances"
  project      = var.project_id
  description  = "Managed by Terraform - Service account for compute instances"
}

# IAM Roles for Service Account
resource "google_project_iam_member" "compute_roles" {
  for_each = toset(var.service_account_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.compute.email}"
}

# -----------------------------------------------------------------------------
# Instance Template
# -----------------------------------------------------------------------------

resource "google_compute_instance_template" "main" {
  name_prefix  = "${local.name_prefix}-template-"
  project      = var.project_id
  region       = var.region
  machine_type = var.machine_type

  description = "Managed by Terraform - Instance template for ${local.name_prefix}"

  # Boot Disk
  disk {
    source_image = var.source_image != "" ? var.source_image : "projects/debian-cloud/global/images/family/debian-12"
    auto_delete  = true
    boot         = true
    disk_type    = var.boot_disk_type
    disk_size_gb = var.boot_disk_size_gb

    labels = local.labels
  }

  # Additional data disk (optional)
  dynamic "disk" {
    for_each = var.data_disk_size_gb > 0 ? [1] : []
    content {
      auto_delete  = true
      boot         = false
      disk_type    = var.data_disk_type
      disk_size_gb = var.data_disk_size_gb
      device_name  = "data-disk"

      labels = local.labels
    }
  }

  # Network Interface
  network_interface {
    network    = var.network_self_link
    subnetwork = var.subnetwork_self_link

    # Optional external IP
    dynamic "access_config" {
      for_each = var.enable_external_ip ? [1] : []
      content {
        network_tier = "PREMIUM"
      }
    }
  }

  # Service Account
  service_account {
    email  = google_service_account.compute.email
    scopes = var.service_account_scopes
  }

  # Metadata and Startup Script
  metadata = merge(var.metadata, {
    startup-script = templatefile("${path.module}/templates/startup.sh", {
      project_id  = var.project_id
      environment = var.environment
      region      = var.region
    })
    enable-oslogin = var.enable_os_login ? "TRUE" : "FALSE"
  })

  # Shielded Instance Configuration
  shielded_instance_config {
    enable_secure_boot          = var.enable_secure_boot
    enable_vtpm                 = var.enable_vtpm
    enable_integrity_monitoring = var.enable_integrity_monitoring
  }

  # Scheduling (preemptible/spot configuration)
  scheduling {
    automatic_restart   = var.preemptible ? false : true
    on_host_maintenance = var.preemptible ? "TERMINATE" : "MIGRATE"
    preemptible         = var.preemptible

    dynamic "node_affinities" {
      for_each = var.node_affinities
      content {
        key      = node_affinities.value.key
        operator = node_affinities.value.operator
        values   = node_affinities.value.values
      }
    }
  }

  # Tags for firewall rules
  tags = var.tags

  # Labels
  labels = local.labels

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Health Check
# -----------------------------------------------------------------------------

resource "google_compute_health_check" "main" {
  name    = "${local.name_prefix}-health-check"
  project = var.project_id

  description = "Managed by Terraform - Health check for ${local.name_prefix}"

  check_interval_sec  = var.health_check_interval_sec
  timeout_sec         = var.health_check_timeout_sec
  healthy_threshold   = var.health_check_healthy_threshold
  unhealthy_threshold = var.health_check_unhealthy_threshold

  dynamic "http_health_check" {
    for_each = var.health_check_type == "HTTP" ? [1] : []
    content {
      port         = var.health_check_port
      request_path = var.health_check_path
    }
  }

  dynamic "https_health_check" {
    for_each = var.health_check_type == "HTTPS" ? [1] : []
    content {
      port         = var.health_check_port
      request_path = var.health_check_path
    }
  }

  dynamic "tcp_health_check" {
    for_each = var.health_check_type == "TCP" ? [1] : []
    content {
      port = var.health_check_port
    }
  }

  log_config {
    enable = var.enable_health_check_logging
  }
}

# -----------------------------------------------------------------------------
# Regional Instance Group Manager
# -----------------------------------------------------------------------------

resource "google_compute_region_instance_group_manager" "main" {
  name    = "${local.name_prefix}-rigm"
  project = var.project_id
  region  = var.region

  description = "Managed by Terraform - Regional instance group manager for ${local.name_prefix}"

  base_instance_name = "${local.name_prefix}-instance"

  version {
    name              = "primary"
    instance_template = google_compute_instance_template.main.id
  }

  # Distribution policy across zones
  distribution_policy_zones        = var.distribution_policy_zones
  distribution_policy_target_shape = var.distribution_policy_target_shape

  # Target pools for load balancing (optional)
  target_pools = var.target_pools

  # Named ports for load balancing
  dynamic "named_port" {
    for_each = var.named_ports
    content {
      name = named_port.value.name
      port = named_port.value.port
    }
  }

  # Auto-healing
  auto_healing_policies {
    health_check      = google_compute_health_check.main.id
    initial_delay_sec = var.auto_healing_initial_delay_sec
  }

  # Update policy
  update_policy {
    type                           = var.update_policy_type
    minimal_action                 = var.update_policy_minimal_action
    most_disruptive_allowed_action = var.update_policy_most_disruptive_action
    max_surge_fixed                = var.update_policy_max_surge_fixed
    max_unavailable_fixed          = var.update_policy_max_unavailable_fixed
    replacement_method             = var.update_policy_replacement_method
  }

  # Stateful configuration (optional)
  dynamic "stateful_disk" {
    for_each = var.stateful_disks
    content {
      device_name = stateful_disk.value.device_name
      delete_rule = stateful_disk.value.delete_rule
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [target_size]
  }

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

# -----------------------------------------------------------------------------
# Regional Autoscaler
# -----------------------------------------------------------------------------

resource "google_compute_region_autoscaler" "main" {
  name    = "${local.name_prefix}-autoscaler"
  project = var.project_id
  region  = var.region
  target  = google_compute_region_instance_group_manager.main.id

  autoscaling_policy {
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    cooldown_period = var.autoscaler_cooldown_period

    # CPU Utilization
    cpu_utilization {
      target            = var.target_cpu_utilization
      predictive_method = var.predictive_autoscaling_mode
    }

    # Load Balancing Utilization (optional)
    dynamic "load_balancing_utilization" {
      for_each = var.target_load_balancing_utilization != null ? [1] : []
      content {
        target = var.target_load_balancing_utilization
      }
    }

    # Custom Metrics (optional)
    dynamic "metric" {
      for_each = var.autoscaling_metrics
      content {
        name   = metric.value.name
        type   = metric.value.type
        target = metric.value.target
      }
    }

    # Scale-in controls
    scale_in_control {
      max_scaled_in_replicas {
        fixed = var.scale_in_control_max_replicas
      }
      time_window_sec = var.scale_in_control_time_window_sec
    }

    # Scaling schedules (optional)
    dynamic "scaling_schedules" {
      for_each = var.scaling_schedules
      content {
        name                  = scaling_schedules.key
        description           = scaling_schedules.value.description
        min_required_replicas = scaling_schedules.value.min_required_replicas
        schedule              = scaling_schedules.value.schedule
        time_zone             = scaling_schedules.value.time_zone
        duration_sec          = scaling_schedules.value.duration_sec
        disabled              = scaling_schedules.value.disabled
      }
    }

    mode = var.autoscaler_mode
  }
}

# -----------------------------------------------------------------------------
# Firewall Rules
# -----------------------------------------------------------------------------

# Allow internal communication
resource "google_compute_firewall" "internal" {
  name    = "${local.name_prefix}-allow-internal"
  project = var.project_id
  network = var.network_self_link

  description = "Managed by Terraform - Allow internal communication for ${local.name_prefix}"

  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = var.internal_source_ranges
  target_tags   = var.tags
}

# Allow health check probes
resource "google_compute_firewall" "health_check" {
  name    = "${local.name_prefix}-allow-health-check"
  project = var.project_id
  network = var.network_self_link

  description = "Managed by Terraform - Allow health check probes for ${local.name_prefix}"

  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = [tostring(var.health_check_port)]
  }

  # GCP health check source ranges
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = var.tags
}

# Allow SSH (optional)
resource "google_compute_firewall" "ssh" {
  count = var.enable_ssh_firewall ? 1 : 0

  name    = "${local.name_prefix}-allow-ssh"
  project = var.project_id
  network = var.network_self_link

  description = "Managed by Terraform - Allow SSH access for ${local.name_prefix}"

  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = var.tags
}

# Allow HTTP/HTTPS (optional)
resource "google_compute_firewall" "http" {
  count = var.enable_http_firewall ? 1 : 0

  name    = "${local.name_prefix}-allow-http"
  project = var.project_id
  network = var.network_self_link

  description = "Managed by Terraform - Allow HTTP/HTTPS traffic for ${local.name_prefix}"

  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = var.http_source_ranges
  target_tags   = var.tags
}

# Custom firewall rules (optional)
resource "google_compute_firewall" "custom" {
  for_each = var.custom_firewall_rules

  name    = "${local.name_prefix}-${each.key}"
  project = var.project_id
  network = var.network_self_link

  description = each.value.description
  direction   = each.value.direction
  priority    = each.value.priority

  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  source_ranges = each.value.source_ranges
  target_tags   = var.tags
}
