variable "name" {
  description = "Project name used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds the resources of this module"
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}

variable "postgresql_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "16"
}

variable "sku_name" {
  description = "Server SKU, for example B_Standard_B1ms (Burstable) or GP_Standard_D2s_v3 (General Purpose)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  description = "Storage size in MB"
  type        = number
  default     = 32768
}

variable "backup_retention_days" {
  description = "Days backups are kept (7-35)"
  type        = number
  default     = 7
}

variable "enable_geo_redundant_backup" {
  description = "Copy backups to the paired region"
  type        = bool
  default     = false
}

variable "enable_high_availability" {
  description = "Run a zone-redundant standby server (not available in the Burstable tier)"
  type        = bool
  default     = false
}

variable "enable_vnet_integration" {
  description = "Place the server in delegated_subnet_id and switch its public endpoint off"
  type        = bool
  default     = false
}

variable "delegated_subnet_id" {
  description = "Subnet delegated to Microsoft.DBforPostgreSQL/flexibleServers (used with enable_vnet_integration)"
  type        = string
  default     = null
}

variable "virtual_network_id" {
  description = "Virtual network that resolves the server's private DNS name (used with enable_vnet_integration)"
  type        = string
  default     = null
}
