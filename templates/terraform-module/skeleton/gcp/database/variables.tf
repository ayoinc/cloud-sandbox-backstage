# -----------------------------------------------------------------------------
# GCP Database Module - Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Common Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "test", "uat"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test, uat."
  }
}

# -----------------------------------------------------------------------------
# Network Variables
# -----------------------------------------------------------------------------

variable "network_self_link" {
  description = "Self link of the VPC network for private IP connectivity"
  type        = string
}

variable "enable_private_ip" {
  description = "Enable private IP for Cloud SQL instance"
  type        = bool
  default     = true
}

variable "enable_public_ip" {
  description = "Enable public IP for Cloud SQL instance (not recommended for production)"
  type        = bool
  default     = false
}

variable "private_ip_prefix_length" {
  description = "Prefix length for private IP range (e.g., 16 for /16 CIDR)"
  type        = number
  default     = 16
}

variable "authorized_networks" {
  description = "List of authorized networks for public IP access"
  type = list(object({
    name = string
    cidr = string
  }))
  default = []
}

variable "require_ssl" {
  description = "Require SSL connections to the database"
  type        = bool
  default     = true
}

variable "enable_private_path_for_google_cloud_services" {
  description = "Enable private path for Google Cloud services"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Cloud SQL Instance Variables
# -----------------------------------------------------------------------------

variable "database_version" {
  description = "Database version (POSTGRES_15, POSTGRES_14, MYSQL_8_0, MYSQL_5_7)"
  type        = string
  default     = "POSTGRES_15"

  validation {
    condition     = can(regex("^(POSTGRES_1[1-6]|MYSQL_[58]_[07])$", var.database_version))
    error_message = "Database version must be a valid Cloud SQL version (e.g., POSTGRES_15, MYSQL_8_0)."
  }
}

variable "tier" {
  description = "Machine tier for the Cloud SQL instance (e.g., db-f1-micro, db-g1-small, db-custom-2-4096)"
  type        = string
  default     = "db-f1-micro"
}

variable "edition" {
  description = "Cloud SQL edition (ENTERPRISE or ENTERPRISE_PLUS)"
  type        = string
  default     = "ENTERPRISE"

  validation {
    condition     = contains(["ENTERPRISE", "ENTERPRISE_PLUS"], var.edition)
    error_message = "Edition must be ENTERPRISE or ENTERPRISE_PLUS."
  }
}

variable "availability_type" {
  description = "Availability type (ZONAL or REGIONAL for high availability)"
  type        = string
  default     = "ZONAL"

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "Availability type must be ZONAL or REGIONAL."
  }
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 10

  validation {
    condition     = var.disk_size >= 10 && var.disk_size <= 65536
    error_message = "Disk size must be between 10 and 65536 GB."
  }
}

variable "disk_type" {
  description = "Disk type (PD_SSD or PD_HDD)"
  type        = string
  default     = "PD_SSD"

  validation {
    condition     = contains(["PD_SSD", "PD_HDD"], var.disk_type)
    error_message = "Disk type must be PD_SSD or PD_HDD."
  }
}

variable "disk_autoresize" {
  description = "Enable automatic disk size increase"
  type        = bool
  default     = true
}

variable "activation_policy" {
  description = "Activation policy (ALWAYS, NEVER, ON_DEMAND)"
  type        = string
  default     = "ALWAYS"

  validation {
    condition     = contains(["ALWAYS", "NEVER", "ON_DEMAND"], var.activation_policy)
    error_message = "Activation policy must be ALWAYS, NEVER, or ON_DEMAND."
  }
}

variable "deletion_protection" {
  description = "Enable deletion protection for the instance"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Database and User Variables
# -----------------------------------------------------------------------------

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.database_name))
    error_message = "Database name must start with a letter and contain only lowercase letters, numbers, and underscores."
  }
}

variable "database_deletion_policy" {
  description = "Deletion policy for the database (DELETE or ABANDON)"
  type        = string
  default     = "DELETE"

  validation {
    condition     = contains(["DELETE", "ABANDON"], var.database_deletion_policy)
    error_message = "Database deletion policy must be DELETE or ABANDON."
  }
}

variable "user_name" {
  description = "Database user name"
  type        = string
  default     = "dbadmin"

  validation {
    condition     = !contains(["postgres", "root", "admin", "cloudsqlsuperuser"], lower(var.user_name))
    error_message = "User name cannot be a reserved name (postgres, root, admin, cloudsqlsuperuser)."
  }
}

variable "user_deletion_policy" {
  description = "Deletion policy for the user (DELETE or ABANDON)"
  type        = string
  default     = "DELETE"

  validation {
    condition     = contains(["DELETE", "ABANDON"], var.user_deletion_policy)
    error_message = "User deletion policy must be DELETE or ABANDON."
  }
}

# -----------------------------------------------------------------------------
# Backup Configuration Variables
# -----------------------------------------------------------------------------

variable "backup_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "Backup start time in HH:MM format (UTC)"
  type        = string
  default     = "03:00"

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", var.backup_start_time))
    error_message = "Backup start time must be in HH:MM format."
  }
}

variable "backup_location" {
  description = "Location for storing backups (region or multi-region)"
  type        = string
  default     = null
}

variable "point_in_time_recovery_enabled" {
  description = "Enable point-in-time recovery (PostgreSQL only)"
  type        = bool
  default     = true
}

variable "transaction_log_retention_days" {
  description = "Number of days to retain transaction logs (1-7)"
  type        = number
  default     = 7

  validation {
    condition     = var.transaction_log_retention_days >= 1 && var.transaction_log_retention_days <= 7
    error_message = "Transaction log retention days must be between 1 and 7."
  }
}

variable "retained_backups" {
  description = "Number of backups to retain"
  type        = number
  default     = 7

  validation {
    condition     = var.retained_backups >= 1 && var.retained_backups <= 365
    error_message = "Retained backups must be between 1 and 365."
  }
}

# -----------------------------------------------------------------------------
# Maintenance Window Variables
# -----------------------------------------------------------------------------

variable "maintenance_window_day" {
  description = "Day of week for maintenance window (1=Monday, 7=Sunday)"
  type        = number
  default     = 7

  validation {
    condition     = var.maintenance_window_day >= 1 && var.maintenance_window_day <= 7
    error_message = "Maintenance window day must be between 1 (Monday) and 7 (Sunday)."
  }
}

variable "maintenance_window_hour" {
  description = "Hour of day for maintenance window (0-23)"
  type        = number
  default     = 4

  validation {
    condition     = var.maintenance_window_hour >= 0 && var.maintenance_window_hour <= 23
    error_message = "Maintenance window hour must be between 0 and 23."
  }
}

variable "maintenance_window_update_track" {
  description = "Maintenance update track (stable or canary)"
  type        = string
  default     = "stable"

  validation {
    condition     = contains(["stable", "canary"], var.maintenance_window_update_track)
    error_message = "Maintenance update track must be stable or canary."
  }
}

variable "deny_maintenance_period" {
  description = "Deny maintenance period configuration"
  type = object({
    start_date = string
    end_date   = string
    time       = string
  })
  default = null
}

# -----------------------------------------------------------------------------
# Query Insights Variables
# -----------------------------------------------------------------------------

variable "query_insights_enabled" {
  description = "Enable Query Insights"
  type        = bool
  default     = true
}

variable "query_string_length" {
  description = "Maximum query string length stored in bytes (256-4500)"
  type        = number
  default     = 1024

  validation {
    condition     = var.query_string_length >= 256 && var.query_string_length <= 4500
    error_message = "Query string length must be between 256 and 4500."
  }
}

variable "record_application_tags" {
  description = "Record application tags in Query Insights"
  type        = bool
  default     = true
}

variable "record_client_address" {
  description = "Record client address in Query Insights"
  type        = bool
  default     = true
}

variable "query_plans_per_minute" {
  description = "Number of query plans to capture per minute (0-20)"
  type        = number
  default     = 5

  validation {
    condition     = var.query_plans_per_minute >= 0 && var.query_plans_per_minute <= 20
    error_message = "Query plans per minute must be between 0 and 20."
  }
}

# -----------------------------------------------------------------------------
# Database Flags Variables
# -----------------------------------------------------------------------------

variable "database_flags" {
  description = "List of database flags to set"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Redis (Memorystore) Variables
# -----------------------------------------------------------------------------

variable "enable_redis" {
  description = "Enable Memorystore Redis"
  type        = bool
  default     = false
}

variable "redis_tier" {
  description = "Redis tier (BASIC or STANDARD_HA)"
  type        = string
  default     = "BASIC"

  validation {
    condition     = contains(["BASIC", "STANDARD_HA"], var.redis_tier)
    error_message = "Redis tier must be BASIC or STANDARD_HA."
  }
}

variable "redis_memory_size_gb" {
  description = "Redis memory size in GB"
  type        = number
  default     = 1

  validation {
    condition     = var.redis_memory_size_gb >= 1 && var.redis_memory_size_gb <= 300
    error_message = "Redis memory size must be between 1 and 300 GB."
  }
}

variable "redis_version" {
  description = "Redis version (REDIS_7_0, REDIS_6_X, REDIS_5_0)"
  type        = string
  default     = "REDIS_7_0"

  validation {
    condition     = can(regex("^REDIS_[567]_[0X]$", var.redis_version))
    error_message = "Redis version must be a valid version (e.g., REDIS_7_0, REDIS_6_X)."
  }
}

variable "redis_connect_mode" {
  description = "Redis connection mode (DIRECT_PEERING or PRIVATE_SERVICE_ACCESS)"
  type        = string
  default     = "DIRECT_PEERING"

  validation {
    condition     = contains(["DIRECT_PEERING", "PRIVATE_SERVICE_ACCESS"], var.redis_connect_mode)
    error_message = "Redis connect mode must be DIRECT_PEERING or PRIVATE_SERVICE_ACCESS."
  }
}

variable "redis_reserved_ip_range" {
  description = "Reserved IP range for Redis (CIDR notation)"
  type        = string
  default     = null
}

variable "redis_configs" {
  description = "Redis configuration parameters"
  type        = map(string)
  default = {
    maxmemory-policy = "volatile-lru"
  }
}

variable "redis_auth_enabled" {
  description = "Enable Redis AUTH"
  type        = bool
  default     = true
}

variable "redis_transit_encryption_mode" {
  description = "Redis transit encryption mode (DISABLED or SERVER_AUTHENTICATION)"
  type        = string
  default     = "SERVER_AUTHENTICATION"

  validation {
    condition     = contains(["DISABLED", "SERVER_AUTHENTICATION"], var.redis_transit_encryption_mode)
    error_message = "Redis transit encryption mode must be DISABLED or SERVER_AUTHENTICATION."
  }
}

variable "redis_maintenance_policy" {
  description = "Redis maintenance policy configuration"
  type = object({
    day          = string
    start_hour   = number
    start_minute = number
  })
  default = null
}

variable "redis_persistence_mode" {
  description = "Redis persistence mode (DISABLED or RDB)"
  type        = string
  default     = null

  validation {
    condition     = var.redis_persistence_mode == null || contains(["DISABLED", "RDB"], var.redis_persistence_mode)
    error_message = "Redis persistence mode must be DISABLED or RDB."
  }
}

variable "redis_rdb_snapshot_period" {
  description = "Redis RDB snapshot period (ONE_HOUR, SIX_HOURS, TWELVE_HOURS, TWENTY_FOUR_HOURS)"
  type        = string
  default     = "TWELVE_HOURS"

  validation {
    condition     = contains(["ONE_HOUR", "SIX_HOURS", "TWELVE_HOURS", "TWENTY_FOUR_HOURS"], var.redis_rdb_snapshot_period)
    error_message = "Redis RDB snapshot period must be ONE_HOUR, SIX_HOURS, TWELVE_HOURS, or TWENTY_FOUR_HOURS."
  }
}

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
