# =============================================================================
# DATABASE MODULE
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "project" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string) }
variable "database_type" { type = string; default = "postgresql" }
variable "sku_name" { type = string; default = "GP_Gen5_2" }
variable "storage_mb" { type = number; default = 32768 }
variable "enable_geo_redundant_backup" { type = bool; default = false }
variable "enable_high_availability" { type = bool; default = false }
variable "subnet_id" { type = string; default = null }
variable "key_vault_id" { type = string; default = null }

locals {
  server_name = "psql-${var.project}-${var.environment}-${var.location}"
}

resource "random_password" "admin_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = local.server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "14"
  administrator_login    = "psqladmin"
  administrator_password = random_password.admin_password.result
  storage_mb             = var.storage_mb
  sku_name               = var.sku_name
  
  geo_redundant_backup_enabled = var.enable_geo_redundant_backup
  
  dynamic "high_availability" {
    for_each = var.enable_high_availability ? [1] : []
    content {
      mode = "ZoneRedundant"
    }
  }

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "${var.project}_${var.environment}"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

output "server_id" { value = azurerm_postgresql_flexible_server.main.id }
output "server_fqdn" { value = azurerm_postgresql_flexible_server.main.fqdn }
output "database_name" { value = azurerm_postgresql_flexible_server_database.main.name }
output "connection_string" {
  value     = "postgresql://psqladmin:${random_password.admin_password.result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}"
  sensitive = true
}
