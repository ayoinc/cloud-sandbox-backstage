variable "project_name" {
  description = "The name of the project for labeling purposes"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID where the Redis instance will be created"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "The GCP region for the Redis instance"
  type        = string
}

variable "name" {
  description = "The ID of the Redis instance"
  type        = string
}

variable "display_name" {
  description = "An arbitrary and optional user-provided name for the instance"
  type        = string
  default     = null
}

variable "tier" {
  description = "The service tier of the instance. Valid values are BASIC and STANDARD_HA"
  type        = string
  default     = "STANDARD_HA"

  validation {
    condition     = contains(["BASIC", "STANDARD_HA"], var.tier)
    error_message = "Tier must be either BASIC or STANDARD_HA."
  }
}

variable "memory_size_gb" {
  description = "Redis memory size in GiB"
  type        = number
  default     = 1

  validation {
    condition     = var.memory_size_gb >= 1
    error_message = "Memory size must be at least 1 GiB."
  }
}

variable "redis_version" {
  description = "The version of Redis software"
  type        = string
  default     = "REDIS_7_0"

  validation {
    condition     = can(regex("^REDIS_[0-9]+_[0-9X]+$", var.redis_version))
    error_message = "Redis version must be in format REDIS_X_X (e.g., REDIS_7_0)."
  }
}

variable "authorized_network" {
  description = "The full name of the Google Compute Engine network to which the instance is connected"
  type        = string
}

variable "connect_mode" {
  description = "The connection mode of the Redis instance. Valid values are DIRECT_PEERING and PRIVATE_SERVICE_ACCESS"
  type        = string
  default     = "PRIVATE_SERVICE_ACCESS"

  validation {
    condition     = contains(["DIRECT_PEERING", "PRIVATE_SERVICE_ACCESS"], var.connect_mode)
    error_message = "Connect mode must be either DIRECT_PEERING or PRIVATE_SERVICE_ACCESS."
  }
}

variable "reserved_ip_range" {
  description = "The CIDR range of internal addresses that are reserved for this instance"
  type        = string
  default     = null
}

variable "auth_enabled" {
  description = "Indicates whether OSS Redis AUTH is enabled for the instance"
  type        = bool
  default     = true
}

variable "transit_encryption_mode" {
  description = "The TLS mode of the Redis instance. Valid values are DISABLED and SERVER_AUTHENTICATION"
  type        = string
  default     = "SERVER_AUTHENTICATION"

  validation {
    condition     = contains(["DISABLED", "SERVER_AUTHENTICATION"], var.transit_encryption_mode)
    error_message = "Transit encryption mode must be either DISABLED or SERVER_AUTHENTICATION."
  }
}

variable "customer_managed_key" {
  description = "The full resource name of the customer managed encryption key (CMEK)"
  type        = string
  default     = null
}

variable "persistence_mode" {
  description = "The persistence mode. Valid values are DISABLED and RDB"
  type        = string
  default     = "RDB"

  validation {
    condition     = contains(["DISABLED", "RDB"], var.persistence_mode)
    error_message = "Persistence mode must be either DISABLED or RDB."
  }
}

variable "rdb_snapshot_period" {
  description = "The snapshot period. Valid values are ONE_HOUR, SIX_HOURS, TWELVE_HOURS, TWENTY_FOUR_HOURS"
  type        = string
  default     = "TWELVE_HOURS"

  validation {
    condition     = contains(["ONE_HOUR", "SIX_HOURS", "TWELVE_HOURS", "TWENTY_FOUR_HOURS"], var.rdb_snapshot_period)
    error_message = "RDB snapshot period must be one of: ONE_HOUR, SIX_HOURS, TWELVE_HOURS, TWENTY_FOUR_HOURS."
  }
}

variable "rdb_snapshot_start_time" {
  description = "Date and time that the first snapshot was/will be attempted in RFC3339 format"
  type        = string
  default     = null
}

variable "maintenance_day" {
  description = "The day of week that maintenance updates occur. Valid values are MONDAY through SUNDAY"
  type        = string
  default     = null

  validation {
    condition = var.maintenance_day == null || contains([
      "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"
    ], var.maintenance_day)
    error_message = "Maintenance day must be a valid day of the week (MONDAY through SUNDAY)."
  }
}

variable "maintenance_start_hour" {
  description = "The hour of the day (0-23) when maintenance updates start"
  type        = number
  default     = null

  validation {
    condition     = var.maintenance_start_hour == null || (var.maintenance_start_hour >= 0 && var.maintenance_start_hour <= 23)
    error_message = "Maintenance start hour must be between 0 and 23."
  }
}

variable "redis_configs" {
  description = "Redis configuration parameters. See https://cloud.google.com/memorystore/docs/redis/reference/rest/v1/projects.locations.instances#Instance.FIELDS.redis_configs"
  type        = map(string)
  default     = {}
}

variable "replica_count" {
  description = "The number of replica nodes. Valid range is 0-5 and applies only to STANDARD_HA tier"
  type        = number
  default     = 1

  validation {
    condition     = var.replica_count >= 0 && var.replica_count <= 5
    error_message = "Replica count must be between 0 and 5."
  }
}

variable "read_replicas_mode" {
  description = "Read replicas mode. Valid values are READ_REPLICAS_DISABLED and READ_REPLICAS_ENABLED"
  type        = string
  default     = "READ_REPLICAS_DISABLED"

  validation {
    condition     = contains(["READ_REPLICAS_DISABLED", "READ_REPLICAS_ENABLED"], var.read_replicas_mode)
    error_message = "Read replicas mode must be either READ_REPLICAS_DISABLED or READ_REPLICAS_ENABLED."
  }
}

variable "labels" {
  description = "Resource labels to apply to the Redis instance"
  type        = map(string)
  default     = {}
}
