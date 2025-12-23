# Azure Database Module
# Reusable module for creating Azure PostgreSQL Flexible Server and other database resources

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "this" {
  for_each = var.postgresql_flexible_servers

  name                          = each.key
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = each.value.version
  delegated_subnet_id           = each.value.delegated_subnet_id
  private_dns_zone_id           = each.value.private_dns_zone_id
  public_network_access_enabled = each.value.public_network_access_enabled
  administrator_login           = each.value.administrator_login
  administrator_password        = each.value.administrator_password
  zone                          = each.value.zone
  storage_mb                    = each.value.storage_mb
  storage_tier                  = each.value.storage_tier
  sku_name                      = each.value.sku_name
  backup_retention_days         = each.value.backup_retention_days
  geo_redundant_backup_enabled  = each.value.geo_redundant_backup_enabled
  auto_grow_enabled             = each.value.auto_grow_enabled

  dynamic "authentication" {
    for_each = each.value.authentication != null ? [each.value.authentication] : []
    content {
      active_directory_auth_enabled = authentication.value.active_directory_auth_enabled
      password_auth_enabled         = authentication.value.password_auth_enabled
      tenant_id                     = authentication.value.tenant_id
    }
  }

  dynamic "high_availability" {
    for_each = each.value.high_availability != null ? [each.value.high_availability] : []
    content {
      mode                      = high_availability.value.mode
      standby_availability_zone = high_availability.value.standby_availability_zone
    }
  }

  dynamic "maintenance_window" {
    for_each = each.value.maintenance_window != null ? [each.value.maintenance_window] : []
    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]
  }
}

# PostgreSQL Flexible Server Database
resource "azurerm_postgresql_flexible_server_database" "this" {
  for_each = var.postgresql_databases

  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.this[each.value.server_key].id
  collation = each.value.collation
  charset   = each.value.charset
}

# PostgreSQL Flexible Server Configuration
resource "azurerm_postgresql_flexible_server_configuration" "this" {
  for_each = var.postgresql_configurations

  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.this[each.value.server_key].id
  value     = each.value.value
}

# PostgreSQL Flexible Server Firewall Rule
resource "azurerm_postgresql_flexible_server_firewall_rule" "this" {
  for_each = var.postgresql_firewall_rules

  name             = each.key
  server_id        = azurerm_postgresql_flexible_server.this[each.value.server_key].id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

# Private DNS Zone for PostgreSQL (optional)
resource "azurerm_private_dns_zone" "postgresql" {
  count = var.create_postgresql_private_dns_zone ? 1 : 0

  name                = "${var.postgresql_private_dns_zone_prefix}.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Private DNS Zone VNet Link
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  count = var.create_postgresql_private_dns_zone && var.postgresql_vnet_id != null ? 1 : 0

  name                  = "${var.postgresql_private_dns_zone_prefix}-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgresql[0].name
  virtual_network_id    = var.postgresql_vnet_id
  resource_group_name   = var.resource_group_name
  registration_enabled  = false
  tags                  = var.tags
}
