# =============================================================================
# Azure Database for PostgreSQL Module - Variables
# =============================================================================
# =============================================================================

variable "name" {
  description = "Name used in resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name))
    error_message = "The name must start with a letter and contain only lowercase letters, digits and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be dev, staging or prod."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "description" {
  description = "Purpose of the resources, added as a tag"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner of the resources, added as a tag"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Server
# -----------------------------------------------------------------------------

variable "postgresql_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "17"
}

variable "sku_name" {
  description = "Compute size as <tier>_<vm size>: B_ (Burstable), GP_ (General Purpose) or MO_ (Memory Optimized)"
  type        = string
  default     = "GP_Standard_D2ds_v5"

  validation {
    condition     = can(regex("^(B|GP|MO)_Standard_", var.sku_name))
    error_message = "The SKU must start with B_Standard_, GP_Standard_ or MO_Standard_."
  }
}

variable "storage_gb" {
  description = "Storage size in GiB: 32, 64, 128, 256, 512, 1024, 2048 or 4096. Storage grows automatically and never shrinks"
  type        = number
  default     = 32

  validation {
    condition     = contains([32, 64, 128, 256, 512, 1024, 2048, 4096], var.storage_gb)
    error_message = "The storage size must be 32, 64, 128, 256, 512, 1024, 2048 or 4096 GiB."
  }
}

variable "high_availability_mode" {
  description = "Standby replica with automatic failover: Disabled, ZoneRedundant (standby in another zone) or SameZone. Not available in the Burstable tier"
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Disabled", "ZoneRedundant", "SameZone"], var.high_availability_mode)
    error_message = "The high availability mode must be Disabled, ZoneRedundant or SameZone."
  }

  validation {
    condition     = var.high_availability_mode == "Disabled" || !startswith(var.sku_name, "B_")
    error_message = "High availability needs a General Purpose or Memory Optimized SKU."
  }
}

variable "backup_retention_days" {
  description = "Days of point-in-time restore"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "The backup retention must be between 7 and 35 days."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Copy backups to the paired region. It cannot be changed after creation"
  type        = bool
  default     = false
}

variable "maintenance_window" {
  description = "Weekly window for patches, in UTC. day_of_week 0 is Sunday"
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = number
  })
  default = {
    day_of_week  = 0
    start_hour   = 3
    start_minute = 0
  }
}

variable "server_parameters" {
  description = "PostgreSQL server parameters to set, by name"
  type        = map(string)
  default = {
    "connection_throttle.enable" = "on"
    "log_checkpoints"            = "on"
  }
}

variable "database_names" {
  description = "Databases to create on the server"
  type        = set(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Authentication
# -----------------------------------------------------------------------------

variable "entra_administrators" {
  description = "Entra ID users, groups or service principals that administer the server. Password authentication is disabled, so at least one is needed to sign in"
  type = list(object({
    object_id      = string
    principal_name = string
    principal_type = string
  }))

  validation {
    condition     = alltrue([for admin in var.entra_administrators : contains(["Group", "User", "ServicePrincipal"], admin.principal_type)])
    error_message = "The principal type of an administrator must be Group, User or ServicePrincipal."
  }
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

variable "virtual_network_address_space" {
  description = "Address space of the virtual network created for the server. Ignored when delegated_subnet_id is set"
  type        = string
  default     = "10.60.0.0/24"
}

variable "delegated_subnet_id" {
  description = "Existing subnet delegated to Microsoft.DBforPostgreSQL/flexibleServers; null creates a virtual network and subnet"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Existing private DNS zone ending in .postgres.database.azure.com and linked to the network; required with delegated_subnet_id"
  type        = string
  default     = null

  validation {
    condition     = (var.delegated_subnet_id == null) == (var.private_dns_zone_id == null)
    error_message = "Set delegated_subnet_id and private_dns_zone_id together, or neither."
  }
}

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace that receives the server logs and metrics; null sends none"
  type        = string
  default     = null
}
