# Azure Database Module - Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "postgresql_flexible_servers" {
  description = "Map of PostgreSQL Flexible Servers to create"
  type = map(object({
    version                       = string
    delegated_subnet_id           = optional(string)
    private_dns_zone_id           = optional(string)
    public_network_access_enabled = optional(bool, false)
    administrator_login           = string
    administrator_password        = string
    zone                          = optional(string, "1")
    storage_mb                    = optional(number, 32768)
    storage_tier                  = optional(string, "P4")
    sku_name                      = optional(string, "B_Standard_B1ms")
    backup_retention_days         = optional(number, 7)
    geo_redundant_backup_enabled  = optional(bool, false)
    auto_grow_enabled             = optional(bool, false)
    authentication = optional(object({
      active_directory_auth_enabled = optional(bool, false)
      password_auth_enabled         = optional(bool, true)
      tenant_id                     = optional(string)
    }))
    high_availability = optional(object({
      mode                      = string
      standby_availability_zone = optional(string)
    }))
    maintenance_window = optional(object({
      day_of_week  = optional(number, 0)
      start_hour   = optional(number, 0)
      start_minute = optional(number, 0)
    }))
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
  }))
  default = {}
}

variable "postgresql_databases" {
  description = "Map of PostgreSQL databases to create"
  type = map(object({
    name       = string
    server_key = string
    collation  = optional(string, "en_US.utf8")
    charset    = optional(string, "UTF8")
  }))
  default = {}
}

variable "postgresql_configurations" {
  description = "Map of PostgreSQL server configurations"
  type = map(object({
    name       = string
    server_key = string
    value      = string
  }))
  default = {}
}

variable "postgresql_firewall_rules" {
  description = "Map of PostgreSQL firewall rules"
  type = map(object({
    server_key       = string
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

variable "create_postgresql_private_dns_zone" {
  description = "Whether to create a private DNS zone for PostgreSQL"
  type        = bool
  default     = false
}

variable "postgresql_private_dns_zone_prefix" {
  description = "Prefix for the PostgreSQL private DNS zone name"
  type        = string
  default     = "privatelink"
}

variable "postgresql_vnet_id" {
  description = "Virtual Network ID to link to the PostgreSQL private DNS zone"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
