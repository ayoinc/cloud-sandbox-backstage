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
  default_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "google_redis_instance" "this" {
  project        = var.project_id
  name           = var.name
  display_name   = var.display_name != null ? var.display_name : var.name
  region         = var.region
  tier           = var.tier
  memory_size_gb = var.memory_size_gb
  redis_version  = var.redis_version

  # Network configuration
  authorized_network = var.authorized_network
  connect_mode       = var.connect_mode
  reserved_ip_range  = var.reserved_ip_range

  # Authentication and encryption
  auth_enabled            = var.auth_enabled
  transit_encryption_mode = var.transit_encryption_mode
  customer_managed_key    = var.customer_managed_key

  # Persistence configuration
  persistence_config {
    persistence_mode        = var.persistence_mode
    rdb_snapshot_period     = var.persistence_mode == "RDB" ? var.rdb_snapshot_period : null
    rdb_snapshot_start_time = var.persistence_mode == "RDB" ? var.rdb_snapshot_start_time : null
  }

  # Maintenance policy
  dynamic "maintenance_policy" {
    for_each = var.maintenance_day != null ? [1] : []
    content {
      weekly_maintenance_window {
        day = var.maintenance_day
        start_time {
          hours   = var.maintenance_start_hour
          minutes = 0
          seconds = 0
          nanos   = 0
        }
      }
    }
  }

  # Redis configuration
  redis_configs = var.redis_configs

  # High availability configuration
  replica_count      = var.tier == "STANDARD_HA" ? var.replica_count : null
  read_replicas_mode = var.tier == "STANDARD_HA" ? var.read_replicas_mode : "READ_REPLICAS_DISABLED"

  labels = merge(local.default_labels, var.labels)

  lifecycle {
    prevent_destroy = true
  }
}
