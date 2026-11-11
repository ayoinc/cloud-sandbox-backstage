# -----------------------------------------------------------------------------
# Azure Database Module - Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Common Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,38}[a-z0-9]$", var.project_name))
    error_message = "Project name must be 2-40 characters of lowercase letters, numbers and hyphens, start with a letter and not end with a hyphen."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,11}$", var.environment))
    error_message = "Environment must be 2-12 lowercase letters or numbers and start with a letter."
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

variable "subnet_id" {
  description = "ID of the subnet delegated to Microsoft.DBforPostgreSQL/flexibleServers that the server joins"
  type        = string

  validation {
    condition     = var.subnet_id != null
    error_message = "subnet_id is required: enable the network module or pass the ID of a subnet delegated to Microsoft.DBforPostgreSQL/flexibleServers."
  }
}

variable "vnet_id" {
  description = "ID of the virtual network linked to the private DNS zones. Null uses the virtual network of subnet_id"
  type        = string
  default     = null
}

variable "private_endpoint_subnet_id" {
  description = "ID of a subnet without delegation for the Redis private endpoint. Required when enable_redis is true"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Key Vault Variables
# -----------------------------------------------------------------------------

variable "store_credentials_in_key_vault" {
  description = "Store the PostgreSQL password and connection string (and the Redis access key when access keys are enabled) as Key Vault secrets. The machine running Terraform must be able to reach the vault and set secrets"
  type        = bool
  default     = false
}

variable "key_vault_id" {
  description = "Key Vault ID for storing database credentials. Required when store_credentials_in_key_vault is true"
  type        = string
  default     = null
}

variable "secret_expiration_date" {
  description = "Expiration date of the Key Vault secrets as an RFC 3339 timestamp (for example 2030-01-01T00:00:00Z). Null sets no expiry"
  type        = string
  default     = null

  validation {
    condition     = var.secret_expiration_date == null || can(formatdate("YYYY", var.secret_expiration_date))
    error_message = "secret_expiration_date must be an RFC 3339 timestamp such as 2030-01-01T00:00:00Z."
  }
}

# -----------------------------------------------------------------------------
# PostgreSQL Server Variables
# -----------------------------------------------------------------------------

variable "postgresql_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "17"

  validation {
    condition     = contains(["14", "15", "16", "17", "18"], var.postgresql_version)
    error_message = "PostgreSQL version must be one of: 14, 15, 16, 17, 18."
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
  description = "Storage size in MB"
  type        = number
  default     = 32768

  validation {
    condition     = contains([32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216, 33553408], var.storage_mb)
    error_message = "Storage must be one of the sizes Azure offers: 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216 or 33553408 MB."
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
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.admin_username)) && !contains(["admin", "administrator", "root", "sa", "postgres", "guest", "public", "azure_superuser", "azure_pg_admin"], var.admin_username) && !startswith(var.admin_username, "pg_")
    error_message = "Admin username must be lowercase letters, numbers and underscores, start with a letter, and not be a reserved name."
  }
}

variable "database_name" {
  description = "Name of the default database to create"
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.database_name))
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
  description = "Availability zone for the PostgreSQL server. Null lets Azure choose, which also works in regions without zones"
  type        = string
  default     = null
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
  description = "Enable geo-redundant backup. Can only be chosen when the server is created"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# High Availability Variables
# -----------------------------------------------------------------------------

variable "enable_high_availability" {
  description = "Enable high availability for PostgreSQL (General Purpose and Memory Optimized SKUs only)"
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
  description = "Availability zone for the standby server. Null lets Azure choose"
  type        = string
  default     = null
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
  description = "Enable Microsoft Entra ID authentication. Requires aad_administrator"
  type        = bool
  default     = false
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID for authentication. Null uses the tenant of the identity running Terraform"
  type        = string
  default     = null
}

variable "aad_administrator" {
  description = "Microsoft Entra principal made administrator of the server when enable_aad_auth is true"
  type = object({
    object_id      = string
    principal_name = string
    principal_type = optional(string, "Group")
  })
  default = null

  validation {
    condition     = var.aad_administrator == null || contains(["Group", "ServicePrincipal", "User"], try(var.aad_administrator.principal_type, ""))
    error_message = "aad_administrator.principal_type must be Group, ServicePrincipal or User."
  }
}

# -----------------------------------------------------------------------------
# PostgreSQL Configuration Variables
# -----------------------------------------------------------------------------

variable "postgresql_configurations" {
  description = "Map of PostgreSQL server configuration parameters"
  type        = map(string)
  nullable    = false
  default = {
    "azure.extensions"           = "PG_TRGM,BTREE_GIST,UUID-OSSP"
    "connection_throttle.enable" = "on"
    "log_checkpoints"            = "on"
    "log_disconnections"         = "on"
    "require_secure_transport"   = "on"
  }
}

variable "maintenance_window" {
  description = "Maintenance window configuration (day_of_week 0 is Sunday). Null lets Azure schedule maintenance"
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = number
  })
  default = null
}

# -----------------------------------------------------------------------------
# Azure Managed Redis Variables
# -----------------------------------------------------------------------------

variable "enable_redis" {
  description = "Create an Azure Managed Redis cache reachable through a private endpoint. Requires private_endpoint_subnet_id"
  type        = bool
  default     = false
}

variable "redis_sku" {
  description = "Azure Managed Redis SKU, for example Balanced_B0, Balanced_B1, MemoryOptimized_M10 or ComputeOptimized_X3"
  type        = string
  default     = "Balanced_B0"

  validation {
    condition     = can(regex("^(Balanced_B|MemoryOptimized_M|ComputeOptimized_X|FlashOptimized_A)[0-9]+$", var.redis_sku))
    error_message = "Redis SKU must be a Balanced_B, MemoryOptimized_M, ComputeOptimized_X or FlashOptimized_A size."
  }
}

variable "redis_high_availability_enabled" {
  description = "Run a replica for every Redis shard. Changing this recreates the cache"
  type        = bool
  default     = true
}

variable "redis_access_keys_enabled" {
  description = "Allow access key authentication in addition to Microsoft Entra ID"
  type        = bool
  default     = false
}

variable "redis_clustering_policy" {
  description = "Redis clustering policy: OSSCluster (cluster-aware clients), EnterpriseCluster (single endpoint) or NoCluster"
  type        = string
  default     = "OSSCluster"

  validation {
    condition     = contains(["OSSCluster", "EnterpriseCluster", "NoCluster"], var.redis_clustering_policy)
    error_message = "Redis clustering policy must be OSSCluster, EnterpriseCluster or NoCluster."
  }
}

variable "redis_eviction_policy" {
  description = "Redis eviction policy applied when memory is full"
  type        = string
  default     = "VolatileLRU"

  validation {
    condition     = contains(["AllKeysLFU", "AllKeysLRU", "AllKeysRandom", "VolatileLRU", "VolatileLFU", "VolatileTTL", "VolatileRandom", "NoEviction"], var.redis_eviction_policy)
    error_message = "Redis eviction policy must be one of: AllKeysLFU, AllKeysLRU, AllKeysRandom, VolatileLRU, VolatileLFU, VolatileTTL, VolatileRandom, NoEviction."
  }
}

variable "create_redis_private_dns_zone" {
  description = "Create the privatelink.redis.azure.net private DNS zone and link it to the virtual network. Disable when the zone already exists and pass redis_private_dns_zone_id"
  type        = bool
  default     = true
}

variable "redis_private_dns_zone_id" {
  description = "ID of an existing privatelink.redis.azure.net private DNS zone, used when create_redis_private_dns_zone is false"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  nullable    = false
  default     = {}
}
