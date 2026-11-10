# =============================================================================
# Database Module
# =============================================================================
# PostgreSQL flexible server with one database. With VNet integration the
# server is reachable only from the virtual network; without it the server has
# a public endpoint whose firewall admits no address until rules are added.
# =============================================================================

locals {
  prefix = "${var.name}-${var.environment}"

  # Zone-redundant standby servers are not offered in the Burstable tier.
  zone_redundant = var.enable_high_availability && !startswith(var.sku_name, "B_")
}

resource "random_password" "admin" {
  length           = 32
  special          = true
  override_special = "!#%*()-_=+[]{}"
}

# -----------------------------------------------------------------------------
# Private DNS (VNet integration)
# -----------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "main" {
  count = var.enable_vnet_integration ? 1 : 0

  name                = "${local.prefix}.private.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  count = var.enable_vnet_integration ? 1 : 0

  name                  = "vnet-${local.prefix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.main[0].name
  virtual_network_id    = var.virtual_network_id
  tags                  = var.tags
}

# -----------------------------------------------------------------------------
# PostgreSQL Flexible Server
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server" "main" {
  #checkov:skip=CKV2_AZURE_57:The server is reached through VNet integration (delegated subnet), which replaces a private endpoint
  #checkov:skip=CKV_AZURE_136:Geo-redundant backups are switched on with disaster recovery
  name                = "psql-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.postgresql_version
  sku_name            = var.sku_name
  storage_mb          = var.storage_mb

  administrator_login    = "psqladmin"
  administrator_password = random_password.admin.result

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.enable_geo_redundant_backup

  delegated_subnet_id           = var.enable_vnet_integration ? var.delegated_subnet_id : null
  private_dns_zone_id           = var.enable_vnet_integration ? azurerm_private_dns_zone.main[0].id : null
  public_network_access_enabled = !var.enable_vnet_integration

  dynamic "high_availability" {
    for_each = local.zone_redundant ? [1] : []

    content {
      mode = "ZoneRedundant"
    }
  }

  lifecycle {
    # Azure picks the zones and may swap them during a failover.
    ignore_changes = [zone, high_availability[0].standby_availability_zone]
  }

  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.main]
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = replace(var.name, "-", "_")
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Connection and checkpoint logging, and throttling of repeated failed logins
resource "azurerm_postgresql_flexible_server_configuration" "main" {
  for_each = {
    "log_connections"            = "on"
    "log_checkpoints"            = "on"
    "connection_throttle.enable" = "on"
  }

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = each.value
}
