# =============================================================================
# GCP CLOUD SQL MODULE
# =============================================================================
# Creates Cloud SQL instance with security and HA configuration
# Supports PostgreSQL, MySQL, and SQL Server
# Provider version: ~> 5.0
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "name" {
  description = "Instance name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "database_version" {
  description = "Database version (POSTGRES_15, MYSQL_8_0, etc.)"
  type        = string
  default     = "POSTGRES_15"
}

variable "tier" {
  description = "Machine type tier"
  type        = string
  default     = "db-f1-micro"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 10
}

variable "disk_type" {
  description = "Disk type (PD_SSD or PD_HDD)"
  type        = string
  default     = "PD_SSD"
}

variable "disk_autoresize" {
  description = "Enable disk autoresize"
  type        = bool
  default     = true
}

variable "disk_autoresize_limit" {
  description = "Maximum disk size for autoresize"
  type        = number
  default     = 0
}

variable "availability_type" {
  description = "Availability type (REGIONAL for HA, ZONAL for single zone)"
  type        = string
  default     = "REGIONAL"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "network" {
  description = "VPC network self_link for private IP"
  type        = string
  default     = null
}

variable "allocated_ip_range" {
  description = "Allocated IP range for private services access"
  type        = string
  default     = null
}

variable "enable_public_ip" {
  description = "Assign public IP"
  type        = bool
  default     = false
}

variable "authorized_networks" {
  description = "Authorized networks for public IP access"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "require_ssl" {
  description = "Require SSL connections"
  type        = bool
  default     = true
}

variable "backup_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "Backup start time (HH:MM)"
  type        = string
  default     = "03:00"
}

variable "backup_location" {
  description = "Backup location"
  type        = string
  default     = null
}

variable "point_in_time_recovery_enabled" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "transaction_log_retention_days" {
  description = "Transaction log retention days"
  type        = number
  default     = 7
}

variable "retained_backups" {
  description = "Number of backups to retain"
  type        = number
  default     = 7
}

variable "maintenance_window_day" {
  description = "Maintenance window day (1-7, Sunday=1)"
  type        = number
  default     = 7
}

variable "maintenance_window_hour" {
  description = "Maintenance window hour (0-23)"
  type        = number
  default     = 3
}

variable "maintenance_window_update_track" {
  description = "Maintenance update track (canary or stable)"
  type        = string
  default     = "stable"
}

variable "database_flags" {
  description = "Database flags"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "databases" {
  description = "Databases to create"
  type = list(object({
    name      = string
    charset   = optional(string, "UTF8")
    collation = optional(string, "en_US.UTF8")
  }))
  default = []
}

variable "users" {
  description = "Users to create"
  type = list(object({
    name     = string
    password = optional(string)
    host     = optional(string, "%")
  }))
  default = []
}

variable "insights_config" {
  description = "Query insights configuration"
  type = object({
    query_insights_enabled  = bool
    query_string_length     = optional(number, 1024)
    record_application_tags = optional(bool, true)
    record_client_address   = optional(bool, true)
  })
  default = {
    query_insights_enabled = true
  }
}

variable "labels" {
  description = "Labels to apply"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  instance_name = "${var.name}-${var.environment}"

  common_labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })

  is_postgres = can(regex("POSTGRES", var.database_version))
  is_mysql    = can(regex("MYSQL", var.database_version))
}

# -----------------------------------------------------------------------------
# Random suffix for instance name (required for recreation)
# -----------------------------------------------------------------------------

resource "random_id" "suffix" {
  byte_length = 4
}

# -----------------------------------------------------------------------------
# Cloud SQL Instance
# -----------------------------------------------------------------------------

resource "google_sql_database_instance" "main" {
  project             = var.project_id
  name                = "${local.instance_name}-${random_id.suffix.hex}"
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    disk_size         = var.disk_size
    disk_type         = var.disk_type
    disk_autoresize   = var.disk_autoresize
    availability_type = var.availability_type

    dynamic "disk_autoresize_limit" {
      for_each = var.disk_autoresize && var.disk_autoresize_limit > 0 ? [1] : []
      content {

      }
    }

    ip_configuration {
      ipv4_enabled       = var.enable_public_ip
      private_network    = var.network
      require_ssl        = var.require_ssl
      allocated_ip_range = var.allocated_ip_range

      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }

    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = var.backup_start_time
      location                       = var.backup_location
      point_in_time_recovery_enabled = var.point_in_time_recovery_enabled
      transaction_log_retention_days = var.transaction_log_retention_days
      backup_retention_settings {
        retained_backups = var.retained_backups
      }
    }

    maintenance_window {
      day          = var.maintenance_window_day
      hour         = var.maintenance_window_hour
      update_track = var.maintenance_window_update_track
    }

    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    dynamic "insights_config" {
      for_each = var.insights_config.query_insights_enabled ? [var.insights_config] : []
      content {
        query_insights_enabled  = insights_config.value.query_insights_enabled
        query_string_length     = insights_config.value.query_string_length
        record_application_tags = insights_config.value.record_application_tags
        record_client_address   = insights_config.value.record_client_address
      }
    }

    user_labels = local.common_labels
  }

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# Databases
# -----------------------------------------------------------------------------

resource "google_sql_database" "databases" {
  for_each = { for db in var.databases : db.name => db }

  project   = var.project_id
  instance  = google_sql_database_instance.main.name
  name      = each.value.name
  charset   = each.value.charset
  collation = local.is_postgres ? each.value.collation : null
}

# -----------------------------------------------------------------------------
# Users
# -----------------------------------------------------------------------------

resource "random_password" "user_passwords" {
  for_each = { for user in var.users : user.name => user if user.password == null }

  length  = 16
  special = true
}

resource "google_sql_user" "users" {
  for_each = { for user in var.users : user.name => user }

  project  = var.project_id
  instance = google_sql_database_instance.main.name
  name     = each.value.name
  password = each.value.password != null ? each.value.password : random_password.user_passwords[each.key].result
  host     = local.is_mysql ? each.value.host : null
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "instance_name" {
  description = "Instance name"
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "Instance connection name"
  value       = google_sql_database_instance.main.connection_name
}

output "instance_self_link" {
  description = "Instance self link"
  value       = google_sql_database_instance.main.self_link
}

output "private_ip_address" {
  description = "Private IP address"
  value       = google_sql_database_instance.main.private_ip_address
}

output "public_ip_address" {
  description = "Public IP address"
  value       = google_sql_database_instance.main.public_ip_address
}

output "database_names" {
  description = "Created database names"
  value       = [for db in google_sql_database.databases : db.name]
}

output "user_names" {
  description = "Created user names"
  value       = [for user in google_sql_user.users : user.name]
}
