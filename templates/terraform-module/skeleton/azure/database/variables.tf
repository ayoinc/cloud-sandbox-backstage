# -----------------------------------------------------------------------------
# Azure Database Module - Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Common Variables
# -----------------------------------------------------------------------------

variable "project" {
  description = "Project name used for resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "test", "uat"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test, uat."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

# -----------------------------------------------------------------------------
# Network Variables
# -----------------------------------------------------------------------------

variable "vnet_id" {
  description = "Virtual Network ID for private DNS zone linking"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for PostgreSQL Flexible Server VNet integration (delegated subnet)"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoints (if different from main subnet)"
  type        = string
  default     = null
}

variable "create_private_endpoint" {
  description = "Whether to create a private endpoint for PostgreSQL (not needed when using delegated subnet)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Key Vault Variables
# -----------------------------------------------------------------------------

variable "key_vault_id" {
  description = "Key Vault ID for storing database credentials"
  type        = string
}

# -----------------------------------------------------------------------------
# PostgreSQL Server Variables
# -----------------------------------------------------------------------------

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"

  validation {
    condition     = contains(["11", "12", "13", "14", "15", "16"], var.postgresql_version)
    error_message = "PostgreSQL version must be one of: 11, 12, 13, 14, 15, 16."
  }
}

variable "sku_name" {
  description = "The SKU name for the PostgreSQL Flexible Server"
  type        = string
  default     = "B_Standard_B1ms"

  validation {
    condition     = can(regex("^(B_Standard_B|GP_Standard_D|MO_Standard_E)", var.sku_name))
    error_message = "SKU name must start with B_Standard_B (Burstable), GP_Standard_D (General Purpose), or MO_Standard_E (Memory Optimized)."
  }
}

variable "storage_mb" {
  description = "Storage size in MB (min 32768, max 16777216)"
  type        = number
  default     = 32768

  validation {
    condition     = var.storage_mb >= 32768 && var.storage_mb <= 16777216
    error_message = "Storage must be between 32768 MB (32 GB) and 16777216 MB (16 TB)."
  }
}

variable "auto_grow_enabled" {
  description = "Enable storage auto-grow"
  type        = bool
  default     = true
}

variable "admin_username" {
  description = "Administrator username for PostgreSQL"
  type        = string
  default     = "psqladmin"

  validation {
    condition     = !contains(["admin", "administrator", "root", "sa", "postgres"], lower(var.admin_username))
    error_message = "Admin username cannot be a reserved name."
  }
}

variable "database_name" {
  description = "Name of the default database to create"
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.database_name))
    error_message = "Database name must start with a letter and contain only lowercase letters, numbers, and underscores."
  }
}

variable "database_collation" {
  description = "Collation for the database"
  type        = string
  default     = "en_US.utf8"
}

variable "database_charset" {
  description = "Character set for the database"
  type        = string
  default     = "UTF8"
}

variable "availability_zone" {
  description = "Availability zone for the PostgreSQL server"
  type        = string
  default     = "1"
}

# -----------------------------------------------------------------------------
# Backup Variables
# -----------------------------------------------------------------------------

variable "backup_retention_days" {
  description = "Backup retention period in days (7-35)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "Backup retention days must be between 7 and 35."
  }
}

variable "geo_redundant_backup" {
  description = "Enable geo-redundant backup"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# High Availability Variables
# -----------------------------------------------------------------------------

variable "enable_high_availability" {
  description = "Enable high availability for PostgreSQL"
  type        = bool
  default     = false
}

variable "high_availability_mode" {
  description = "High availability mode (SameZone or ZoneRedundant)"
  type        = string
  default     = "ZoneRedundant"

  validation {
    condition     = contains(["SameZone", "ZoneRedundant"], var.high_availability_mode)
    error_message = "High availability mode must be SameZone or ZoneRedundant."
  }
}

variable "standby_availability_zone" {
  description = "Availability zone for the standby server"
  type        = string
  default     = "2"
}

# -----------------------------------------------------------------------------
# Authentication Variables
# -----------------------------------------------------------------------------

variable "enable_password_auth" {
  description = "Enable password authentication"
  type        = bool
  default     = true
}

variable "enable_aad_auth" {
  description = "Enable Azure Active Directory authentication"
  type        = bool
  default     = false
}

variable "tenant_id" {
  description = "Azure AD tenant ID (required if enable_aad_auth is true)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Firewall Variables
# -----------------------------------------------------------------------------

variable "firewall_rules" {
  description = "Map of firewall rules to create"
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

variable "allow_azure_services" {
  description = "Allow Azure services to access the PostgreSQL server"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# PostgreSQL Configuration Variables
# -----------------------------------------------------------------------------

variable "postgresql_configurations" {
  description = "Map of PostgreSQL server configuration parameters"
  type        = map(string)
  default = {
    "azure.extensions"      = "PG_TRGM,BTREE_GIST,UUID-OSSP"
    "log_checkpoints"       = "on"
    "log_connections"       = "on"
    "log_disconnections"    = "on"
    "connection_throttling" = "on"
  }
}

variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = number
  })
  default = null
}

# -----------------------------------------------------------------------------
# Redis Cache Variables
# -----------------------------------------------------------------------------

variable "enable_redis" {
  description = "Enable Azure Redis Cache"
  type        = bool
  default     = false
}

variable "redis_sku" {
  description = "Redis Cache SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.redis_sku)
    error_message = "Redis SKU must be Basic, Standard, or Premium."
  }
}

variable "redis_capacity" {
  description = "Redis Cache capacity (0-6 for Basic/Standard, 1-4 for Premium)"
  type        = number
  default     = 1

  validation {
    condition     = var.redis_capacity >= 0 && var.redis_capacity <= 6
    error_message = "Redis capacity must be between 0 and 6."
  }
}

variable "redis_family" {
  description = "Redis Cache family (C for Basic/Standard, P for Premium)"
  type        = string
  default     = "C"

  validation {
    condition     = contains(["C", "P"], var.redis_family)
    error_message = "Redis family must be C (Basic/Standard) or P (Premium)."
  }
}

variable "redis_maxmemory_policy" {
  description = "Redis maxmemory eviction policy"
  type        = string
  default     = "volatile-lru"

  validation {
    condition     = contains(["volatile-lru", "allkeys-lru", "volatile-random", "allkeys-random", "volatile-ttl", "noeviction"], var.redis_maxmemory_policy)
    error_message = "Invalid maxmemory policy."
  }
}

variable "redis_maxmemory_reserved" {
  description = "Redis maxmemory reserved in MB"
  type        = number
  default     = 50
}

variable "redis_maxfragmentationmemory_reserved" {
  description = "Redis max fragmentation memory reserved in MB"
  type        = number
  default     = 50
}

variable "redis_aof_backup_enabled" {
  description = "Enable AOF backup (Premium SKU only)"
  type        = bool
  default     = false
}

variable "redis_aof_storage_connection_string" {
  description = "Storage connection string for AOF backup"
  type        = string
  default     = null
  sensitive   = true
}

variable "redis_patch_schedule" {
  description = "Redis patch schedule configuration"
  type = object({
    day_of_week        = string
    start_hour_utc     = number
    maintenance_window = optional(string, "PT5H")
  })
  default = null
}

variable "redis_private_dns_zone_id" {
  description = "Private DNS zone ID for Redis private endpoint"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
