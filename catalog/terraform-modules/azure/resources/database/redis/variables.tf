variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the Redis cache"
  type        = string
}

variable "redis_name" {
  description = "Name of the Redis cache instance"
  type        = string
}

variable "capacity" {
  description = "The size of the Redis cache (0-6 for Basic/Standard, 1-5 for Premium)"
  type        = number
  default     = 1
}

variable "family" {
  description = "The SKU family/pricing group (C for Basic/Standard, P for Premium)"
  type        = string
  default     = "C"

  validation {
    condition     = contains(["C", "P"], var.family)
    error_message = "Family must be either 'C' (Basic/Standard) or 'P' (Premium)."
  }
}

variable "sku_name" {
  description = "The SKU name (Basic, Standard, or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "SKU name must be Basic, Standard, or Premium."
  }
}

variable "enable_non_ssl_port" {
  description = "Enable the non-SSL port (6379)"
  type        = bool
  default     = false
}

variable "minimum_tls_version" {
  description = "Minimum TLS version supported"
  type        = string
  default     = "1.2"

  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "Minimum TLS version must be 1.0, 1.1, or 1.2."
  }
}

variable "shard_count" {
  description = "Number of shards for Redis cluster (Premium SKU only)"
  type        = number
  default     = null
}

variable "replicas_per_master" {
  description = "Number of replicas per master node (Premium SKU only, 1-3)"
  type        = number
  default     = null

  validation {
    condition     = var.replicas_per_master == null || (var.replicas_per_master >= 1 && var.replicas_per_master <= 3)
    error_message = "Replicas per master must be between 1 and 3."
  }
}

variable "redis_configuration" {
  description = "Redis configuration settings"
  type = object({
    maxmemory_policy                = optional(string, "volatile-lru")
    aof_backup_enabled              = optional(bool, false)
    aof_storage_connection_string_0 = optional(string)
    aof_storage_connection_string_1 = optional(string)
    rdb_backup_enabled              = optional(bool, false)
    rdb_backup_frequency            = optional(number)
    rdb_backup_max_snapshot_count   = optional(number)
    rdb_storage_connection_string   = optional(string)
    maxmemory_reserved              = optional(number)
    maxmemory_delta                 = optional(number)
    maxfragmentationmemory_reserved = optional(number)
    notify_keyspace_events          = optional(string)
  })
  default = null
}

variable "zones" {
  description = "List of availability zones for the Redis cache"
  type        = list(string)
  default     = null
}

variable "private_static_ip_address" {
  description = "Static IP address for private endpoint"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID for VNet integration (Premium SKU only)"
  type        = string
  default     = null
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint deployment"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for private endpoint"
  type        = string
  default     = null
}

variable "firewall_rules" {
  description = "List of firewall rules for the Redis cache"
  type = list(object({
    name     = string
    start_ip = string
    end_ip   = string
  }))
  default = []
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
