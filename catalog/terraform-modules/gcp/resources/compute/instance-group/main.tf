terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

locals {
  labels = merge(
    {
      project     = var.project_name
      environment = var.environment
      managed_by  = "terraform"
    },
    var.labels
  )
}

resource "google_compute_instance_template" "this" {
  project      = var.project_id
  name_prefix  = "${var.name}-"
  machine_type = var.machine_type
  region       = var.region

  labels = local.labels

  disk {
    source_image = var.source_image
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
  }

  tags = var.network_tags

  metadata = merge(
    var.metadata,
    var.startup_script != null ? { startup-script = var.startup_script } : {}
  )

  dynamic "service_account" {
    for_each = var.service_account_email != null ? [1] : []
    content {
      email  = var.service_account_email
      scopes = var.service_account_scopes
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "this" {
  project            = var.project_id
  name               = var.name
  region             = var.region
  base_instance_name = var.base_instance_name
  target_size        = var.enable_autoscaling ? null : var.target_size

  version {
    instance_template = google_compute_instance_template.this.self_link
  }

  dynamic "named_port" {
    for_each = var.named_ports
    content {
      name = named_port.value.name
      port = named_port.value.port
    }
  }

  dynamic "auto_healing_policies" {
    for_each = var.auto_healing_health_check != null ? [1] : []
    content {
      health_check      = var.auto_healing_health_check
      initial_delay_sec = var.initial_delay_sec
    }
  }

  update_policy {
    type                           = var.update_type
    minimal_action                 = "REPLACE"
    most_disruptive_allowed_action = "REPLACE"
    max_surge_fixed                = var.max_surge_fixed
    max_unavailable_fixed          = var.max_unavailable_fixed
    replacement_method             = "SUBSTITUTE"
  }

  dynamic "distribution_policy_zones" {
    for_each = var.distribution_policy_zones != null ? var.distribution_policy_zones : []
    content {
      zone = distribution_policy_zones.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_autoscaler" "this" {
  count = var.enable_autoscaling ? 1 : 0

  project = var.project_id
  name    = "${var.name}-autoscaler"
  region  = var.region
  target  = google_compute_region_instance_group_manager.this.id

  autoscaling_policy {
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    cooldown_period = var.cooldown_period

    cpu_utilization {
      target = var.cpu_target
    }
  }
}
