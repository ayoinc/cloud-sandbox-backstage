# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

# Resource Configuration
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the Cosmos DB account"
  type        = string
}

variable "account_name" {
  description = "Name of the Cosmos DB account"
  type        = string
}

# Account Settings
variable "offer_type" {
  description = "Specifies the Offer Type to use for this Cosmos DB Account"
  type        = string
  default     = "Standard"
}

variable "kind" {
  description = "Specifies the Kind of Cosmos DB account (GlobalDocumentDB, MongoDB, Parse)"
  type        = string
  default     = "GlobalDocumentDB"
}

variable "consistency_level" {
  description = "The Consistency Level (BoundedStaleness, Eventual, Session, Strong, ConsistentPrefix)"
  type        = string
  default     = "Session"

  validation {
    condition     = contains(["BoundedStaleness", "Eventual", "Session", "Strong", "ConsistentPrefix"], var.consistency_level)
    error_message = "Consistency level must be one of: BoundedStaleness, Eventual, Session, Strong, ConsistentPrefix."
  }
}

variable "max_interval_in_seconds" {
  description = "Max interval in seconds for BoundedStaleness consistency (5-86400)"
  type        = number
  default     = 5
}

variable "max_staleness_prefix" {
  description = "Max staleness prefix for BoundedStaleness consistency (10-2147483647)"
  type        = number
  default     = 100
}

# Geo-replication
variable "geo_locations" {
  description = "List of geo locations for the Cosmos DB account"
  type = list(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool, false)
  }))
}

variable "enable_automatic_failover" {
  description = "Enable automatic failover for this Cosmos DB account"
  type        = bool
  default     = true
}

variable "enable_multiple_write_locations" {
  description = "Enable multiple write locations for this Cosmos DB account"
  type        = bool
  default     = false
}

# Free Tier
variable "enable_free_tier" {
  description = "Enable free tier for this Cosmos DB account (only one per subscription)"
  type        = bool
  default     = false
}

# API Capabilities
variable "capabilities" {
  description = "List of capabilities to enable (EnableMongo, EnableCassandra, EnableGremlin, EnableTable, EnableServerless, etc.)"
  type        = list(string)
  default     = []
}

# Databases and Containers
variable "databases" {
  description = "List of databases to create with their containers"
  type = list(object({
    name                     = string
    throughput               = optional(number)
    autoscale_max_throughput = optional(number)
    containers = optional(list(object({
      name                     = string
      partition_key_path       = string
      throughput               = optional(number)
      autoscale_max_throughput = optional(number)
      default_ttl              = optional(number)
      analytical_store_ttl     = optional(number)
      unique_keys              = optional(list(object({ paths = list(string) })), [])
      indexing_policy = optional(object({
        indexing_mode     = optional(string, "consistent")
        included_paths    = optional(list(string), ["/*"])
        excluded_paths    = optional(list(string), ["/\"_etag\"/?"])
        composite_indexes = optional(list(list(object({ path = string, order = string }))))
        spatial_indexes   = optional(list(string))
      }))
    })), [])
  }))
  default = []
}

# Analytical Storage
variable "enable_analytical_storage" {
  description = "Enable analytical storage for this Cosmos DB account"
  type        = bool
  default     = false
}

variable "analytical_storage_schema_type" {
  description = "Schema type for analytical storage (WellDefined or FullFidelity)"
  type        = string
  default     = "WellDefined"
}

# Backup Configuration
variable "backup_type" {
  description = "Type of backup (Periodic or Continuous)"
  type        = string
  default     = "Periodic"

  validation {
    condition     = contains(["Periodic", "Continuous"], var.backup_type)
    error_message = "Backup type must be either Periodic or Continuous."
  }
}

variable "backup_interval_in_minutes" {
  description = "Interval in minutes between backups (60-1440)"
  type        = number
  default     = 240

  validation {
    condition     = var.backup_interval_in_minutes >= 60 && var.backup_interval_in_minutes <= 1440
    error_message = "Backup interval must be between 60 and 1440 minutes."
  }
}

variable "backup_retention_in_hours" {
  description = "Retention period for backups in hours (8-720)"
  type        = number
  default     = 8

  validation {
    condition     = var.backup_retention_in_hours >= 8 && var.backup_retention_in_hours <= 720
    error_message = "Backup retention must be between 8 and 720 hours."
  }
}

variable "backup_storage_redundancy" {
  description = "Storage redundancy for backups (Geo, Local, Zone)"
  type        = string
  default     = "Geo"
}

# Network Configuration
variable "ip_range_filter" {
  description = "Comma-separated list of IP addresses or IP address ranges to allow"
  type        = string
  default     = null
}

variable "is_virtual_network_filter_enabled" {
  description = "Enable virtual network filtering"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "virtual_network_rules" {
  description = "List of virtual network rules"
  type = list(object({
    subnet_id                            = string
    ignore_missing_vnet_service_endpoint = optional(bool, false)
  }))
  default = []
}

# Private Endpoint
variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "private_endpoint_subresource" {
  description = "Subresource name for private endpoint (Sql, MongoDB, Cassandra, Gremlin, Table)"
  type        = string
  default     = "Sql"
}

variable "private_dns_zone_ids" {
  description = "List of private DNS zone IDs for private endpoint"
  type        = list(string)
  default     = null
}

# Identity
variable "identity_type" {
  description = "Type of managed identity (SystemAssigned, UserAssigned, SystemAssigned, UserAssigned)"
  type        = string
  default     = null
}

variable "identity_ids" {
  description = "List of user assigned identity IDs"
  type        = list(string)
  default     = null
}

# CORS
variable "cors_rules" {
  description = "List of CORS rules for the Cosmos DB account"
  type = list(object({
    allowed_headers    = list(string)
    allowed_methods    = list(string)
    allowed_origins    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  }))
  default = []
}

# Conflict Resolution
variable "conflict_resolution_mode" {
  description = "Conflict resolution mode (LastWriterWins or Custom)"
  type        = string
  default     = "LastWriterWins"
}

variable "conflict_resolution_path" {
  description = "Path for LastWriterWins conflict resolution"
  type        = string
  default     = "/_ts"
}

variable "conflict_resolution_procedure" {
  description = "Stored procedure name for Custom conflict resolution"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
