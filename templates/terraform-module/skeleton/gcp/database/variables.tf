variable "project_name" {
  description = "Project name used as a prefix for resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.project_name))
    error_message = "project_name must start with a lowercase letter and contain only lowercase letters, digits and hyphens (max 63 characters)."
  }
}

variable "environment" {
  description = "Environment name (for example dev, staging, prod)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,7}$", var.environment))
    error_message = "environment must be 1-8 lowercase letters or digits and start with a letter."
  }
}

variable "project_id" {
  description = "ID of the Google Cloud project that owns the resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud project ID (6-30 lowercase letters, digits or hyphens)."
  }
}

variable "region" {
  description = "Google Cloud region for regional resources."
  type        = string
}

variable "labels" {
  description = "Labels applied to every resource that supports them."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "network_id" {
  description = "ID of the VPC (projects/<project>/global/networks/<name>) the database is reachable from. Null uses the project's default network."
  type        = string
  default     = null
}

variable "private_ip_range" {
  description = "Name of an allocated range that is already peered with Google managed services on the VPC. Null makes the module reserve and peer its own range."
  type        = string
  default     = null
}

variable "private_ip_prefix_length" {
  description = "Prefix length of the range reserved when private_ip_range is null."
  type        = number
  default     = 20

  validation {
    condition     = var.private_ip_prefix_length >= 16 && var.private_ip_prefix_length <= 24
    error_message = "private_ip_prefix_length must be between 16 and 24."
  }
}

variable "database_version" {
  description = "Cloud SQL engine and major version, PostgreSQL or MySQL."
  type        = string
  default     = "POSTGRES_17"

  validation {
    condition     = can(regex("^(POSTGRES_(1[4-9]|[2-9][0-9])|MYSQL_8_[04])$", var.database_version))
    error_message = "database_version must be POSTGRES_14 or newer, MYSQL_8_0 or MYSQL_8_4."
  }
}

variable "edition" {
  description = "Cloud SQL edition: ENTERPRISE or ENTERPRISE_PLUS. The tier must belong to the edition."
  type        = string
  default     = "ENTERPRISE"

  validation {
    condition     = contains(["ENTERPRISE", "ENTERPRISE_PLUS"], var.edition)
    error_message = "edition must be ENTERPRISE or ENTERPRISE_PLUS."
  }
}

variable "tier" {
  description = "Machine tier of the instance (db-custom-<vCPUs>-<memory MB> for ENTERPRISE, db-perf-optimized-N-<size> for ENTERPRISE_PLUS)."
  type        = string
  default     = "db-custom-1-3840"
}

variable "high_availability" {
  description = "Run a standby in a second zone with automatic failover."
  type        = bool
  default     = false
}

variable "disk_size_gb" {
  description = "Initial size of the data disk in GB. The disk grows automatically."
  type        = number
  default     = 20

  validation {
    condition     = var.disk_size_gb >= 10
    error_message = "disk_size_gb must be at least 10."
  }
}

variable "kms_key_id" {
  description = "ID of a Cloud KMS key in region that encrypts the instance and the Redis cache. The Cloud SQL and Memorystore service agents must be allowed to use it. Null uses Google-managed encryption."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Protect the instance against deletion, in Terraform and in the Cloud SQL API."
  type        = bool
  default     = true
}

variable "database_name" {
  description = "Name of the application database."
  type        = string
  default     = "app"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_]{0,62}$", var.database_name))
    error_message = "database_name must start with a lowercase letter or underscore and contain only lowercase letters, digits and underscores."
  }
}

variable "user_name" {
  description = "Name of the application database user. Its generated password is stored in Secret Manager."
  type        = string
  default     = "app"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_]{0,30}$", var.user_name)) && !contains(["postgres", "root"], var.user_name)
    error_message = "user_name must be a lowercase identifier other than postgres or root."
  }
}

variable "database_flags" {
  description = "Database flags merged over the module's hardening defaults (connection and lock logging for PostgreSQL, local_infile off for MySQL)."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "backup_enabled" {
  description = "Take daily backups and keep transaction logs for point-in-time recovery."
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "Start of the daily backup window in UTC, HH:MM."
  type        = string
  default     = "03:00"

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", var.backup_start_time))
    error_message = "backup_start_time must use the 24-hour HH:MM format."
  }
}

variable "retained_backups" {
  description = "Number of daily backups to keep."
  type        = number
  default     = 7

  validation {
    condition     = var.retained_backups >= 1 && var.retained_backups <= 365
    error_message = "retained_backups must be between 1 and 365."
  }
}

variable "maintenance_window_day" {
  description = "Day of the week for maintenance, 1 (Monday) to 7 (Sunday)."
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 2, 3, 4, 5, 6, 7], var.maintenance_window_day)
    error_message = "maintenance_window_day must be between 1 and 7."
  }
}

variable "maintenance_window_hour" {
  description = "Hour of the day in UTC at which maintenance starts, 0 to 23."
  type        = number
  default     = 4

  validation {
    condition     = var.maintenance_window_hour >= 0 && var.maintenance_window_hour <= 23 && floor(var.maintenance_window_hour) == var.maintenance_window_hour
    error_message = "maintenance_window_hour must be a whole number between 0 and 23."
  }
}

variable "query_insights_enabled" {
  description = "Collect query performance data with Query Insights."
  type        = bool
  default     = true
}

variable "enable_redis" {
  description = "Create a Memorystore for Redis instance with AUTH and in-transit encryption."
  type        = bool
  default     = false
}

variable "redis_tier" {
  description = "Memorystore tier: BASIC (single node) or STANDARD_HA (replicated with failover)."
  type        = string
  default     = "BASIC"

  validation {
    condition     = contains(["BASIC", "STANDARD_HA"], var.redis_tier)
    error_message = "redis_tier must be BASIC or STANDARD_HA."
  }
}

variable "redis_memory_size_gb" {
  description = "Memory of the Redis instance in GB."
  type        = number
  default     = 1

  validation {
    condition     = var.redis_memory_size_gb >= 1 && var.redis_memory_size_gb <= 300
    error_message = "redis_memory_size_gb must be between 1 and 300."
  }
}

variable "redis_version" {
  description = "Redis version such as REDIS_7_2. Null uses the current Memorystore default."
  type        = string
  default     = null

  validation {
    condition     = var.redis_version == null || can(regex("^REDIS_[0-9]+_[0-9X]+$", var.redis_version))
    error_message = "redis_version must look like REDIS_7_2."
  }
}
