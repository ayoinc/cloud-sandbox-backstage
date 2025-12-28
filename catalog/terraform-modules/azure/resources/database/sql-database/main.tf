# =============================================================================
# AZURE SQL DATABASE MODULE
# =============================================================================
# Creates Azure SQL Server and databases with security features
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "administrator_login" {
  description = "SQL Server administrator login"
  type        = string
}

variable "administrator_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}

variable "sql_version" {
  description = "SQL Server version"
  type        = string
  default     = "12.0"
}

variable "minimum_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "azuread_administrator" {
  description = "Azure AD administrator configuration"
  type = object({
    login_username              = string
    object_id                   = string
    azuread_authentication_only = optional(bool, false)
  })
  default = null
}

variable "databases" {
  description = "Map of databases to create"
  type = map(object({
    collation                   = optional(string, "SQL_Latin1_General_CP1_CI_AS")
    sku_name                    = optional(string, "S0")
    max_size_gb                 = optional(number, 4)
    zone_redundant              = optional(bool, false)
    read_replica_count          = optional(number, 0)
    auto_pause_delay_in_minutes = optional(number, null)
    min_capacity                = optional(number, null)
    geo_backup_enabled          = optional(bool, true)
    storage_account_type        = optional(string, "Geo")
    short_term_retention_days   = optional(number, 7)
    long_term_retention_weekly  = optional(string, null)
    long_term_retention_monthly = optional(string, null)
    long_term_retention_yearly  = optional(string, null)
  }))
  default = {}
}

variable "firewall_rules" {
  description = "Firewall rules"
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

variable "allow_azure_services" {
  description = "Allow Azure services to access the server"
  type        = bool
  default     = true
}

variable "virtual_network_rules" {
  description = "Virtual network rules"
  type = map(object({
    subnet_id = string
  }))
  default = {}
}

variable "enable_threat_detection" {
  description = "Enable advanced threat detection"
  type        = bool
  default     = true
}

variable "audit_storage_account_id" {
  description = "Storage account ID for audit logs"
  type        = string
  default     = null
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  server_name = "sql-${var.project}-${var.environment}-${substr(md5("${var.project}-${var.environment}"), 0, 8)}"
}

# -----------------------------------------------------------------------------
# SQL Server
# -----------------------------------------------------------------------------

resource "azurerm_mssql_server" "main" {
  name                          = local.server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.sql_version
  administrator_login           = var.administrator_login
  administrator_login_password  = var.administrator_password
  minimum_tls_version           = var.minimum_tls_version
  public_network_access_enabled = var.public_network_access_enabled

  dynamic "azuread_administrator" {
    for_each = var.azuread_administrator != null ? [var.azuread_administrator] : []
    content {
      login_username              = azuread_administrator.value.login_username
      object_id                   = azuread_administrator.value.object_id
      azuread_authentication_only = azuread_administrator.value.azuread_authentication_only
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Databases
# -----------------------------------------------------------------------------

resource "azurerm_mssql_database" "databases" {
  for_each = var.databases

  name                        = each.key
  server_id                   = azurerm_mssql_server.main.id
  collation                   = each.value.collation
  sku_name                    = each.value.sku_name
  max_size_gb                 = each.value.max_size_gb
  zone_redundant              = each.value.zone_redundant
  read_replica_count          = each.value.read_replica_count
  auto_pause_delay_in_minutes = each.value.auto_pause_delay_in_minutes
  min_capacity                = each.value.min_capacity
  geo_backup_enabled          = each.value.geo_backup_enabled
  storage_account_type        = each.value.storage_account_type

  short_term_retention_policy {
    retention_days = each.value.short_term_retention_days
  }

  dynamic "long_term_retention_policy" {
    for_each = each.value.long_term_retention_weekly != null || each.value.long_term_retention_monthly != null || each.value.long_term_retention_yearly != null ? [1] : []
    content {
      weekly_retention  = each.value.long_term_retention_weekly
      monthly_retention = each.value.long_term_retention_monthly
      yearly_retention  = each.value.long_term_retention_yearly
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Firewall Rules
# -----------------------------------------------------------------------------

resource "azurerm_mssql_firewall_rule" "rules" {
  for_each = var.firewall_rules

  name             = each.key
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

resource "azurerm_mssql_firewall_rule" "azure_services" {
  count = var.allow_azure_services ? 1 : 0

  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# -----------------------------------------------------------------------------
# Virtual Network Rules
# -----------------------------------------------------------------------------

resource "azurerm_mssql_virtual_network_rule" "rules" {
  for_each = var.virtual_network_rules

  name      = each.key
  server_id = azurerm_mssql_server.main.id
  subnet_id = each.value.subnet_id
}

# -----------------------------------------------------------------------------
# Private Endpoint
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "sql" {
  count = var.enable_private_endpoint && var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "pe-${azurerm_mssql_server.main.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_mssql_server.main.name}"
    private_connection_resource_id = azurerm_mssql_server.main.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "server_id" {
  description = "SQL Server ID"
  value       = azurerm_mssql_server.main.id
}

output "server_name" {
  description = "SQL Server name"
  value       = azurerm_mssql_server.main.name
}

output "server_fqdn" {
  description = "SQL Server FQDN"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "database_ids" {
  description = "Map of database names to IDs"
  value       = { for k, v in azurerm_mssql_database.databases : k => v.id }
}

output "connection_strings" {
  description = "Map of database connection strings"
  value = {
    for k, v in azurerm_mssql_database.databases : k =>
    "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Database=${k};Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;"
  }
  sensitive = true
}
