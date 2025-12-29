variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "server_name" {
  description = "The name of the PostgreSQL Flexible Server"
  type        = string
}

variable "administrator_login" {
  description = "The administrator login for the PostgreSQL server"
  type        = string
}

variable "administrator_password" {
  description = "The administrator password for the PostgreSQL server"
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "The SKU name for the PostgreSQL Flexible Server"
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "storage_mb" {
  description = "The storage capacity in MB for the PostgreSQL server"
  type        = number
  default     = 32768
}

variable "version" {
  description = "The version of PostgreSQL to use"
  type        = string
  default     = "15"
}

variable "zone" {
  description = "The availability zone for the PostgreSQL server"
  type        = string
  default     = null
}

variable "high_availability_mode" {
  description = "The high availability mode for the PostgreSQL server (Disabled, ZoneRedundant, SameZone)"
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Disabled", "ZoneRedundant", "SameZone"], var.high_availability_mode)
    error_message = "high_availability_mode must be one of: Disabled, ZoneRedundant, SameZone"
  }
}

variable "standby_availability_zone" {
  description = "The availability zone for the standby server when HA is enabled"
  type        = string
  default     = null
}

variable "backup_retention_days" {
  description = "The number of days to retain backups"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 7 and 35"
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Whether geo-redundant backups are enabled"
  type        = bool
  default     = false
}

variable "delegated_subnet_id" {
  description = "The ID of the subnet to delegate to the PostgreSQL server for VNet integration"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "The ID of the private DNS zone for VNet integration"
  type        = string
  default     = null
}

variable "maintenance_window" {
  description = "The maintenance window configuration"
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = number
  })
  default = null

  validation {
    condition     = var.maintenance_window == null || (var.maintenance_window.day_of_week >= 0 && var.maintenance_window.day_of_week <= 6)
    error_message = "day_of_week must be between 0 (Sunday) and 6 (Saturday)"
  }

  validation {
    condition     = var.maintenance_window == null || (var.maintenance_window.start_hour >= 0 && var.maintenance_window.start_hour <= 23)
    error_message = "start_hour must be between 0 and 23"
  }

  validation {
    condition     = var.maintenance_window == null || (var.maintenance_window.start_minute >= 0 && var.maintenance_window.start_minute <= 59)
    error_message = "start_minute must be between 0 and 59"
  }
}

variable "databases" {
  description = "List of databases to create on the PostgreSQL server"
  type = list(object({
    name      = string
    charset   = string
    collation = string
  }))
  default = []
}

variable "configurations" {
  description = "Map of PostgreSQL server configurations to apply"
  type        = map(string)
  default     = {}
}

variable "firewall_rules" {
  description = "List of firewall rules to create for the PostgreSQL server"
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
