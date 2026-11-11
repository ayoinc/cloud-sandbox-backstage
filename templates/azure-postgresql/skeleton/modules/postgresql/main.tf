# =============================================================================
# Azure Database for PostgreSQL Module
# =============================================================================
# Creates a PostgreSQL flexible server that has no public endpoint and no
# passwords:
# - Resource group
# - Virtual network, delegated subnet and private DNS zone (or existing ones)
# - Flexible server with Entra ID authentication only
# - Entra ID administrators, databases and server parameters
# - Optional zone-redundant standby and diagnostic logs
# =============================================================================

data "azurerm_client_config" "current" {}

locals {
  resource_group_name = "rg-${var.name}-${var.environment}"
  server_name         = "psql-${var.name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Project     = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.owner != "" ? { Owner = var.owner } : {},
    var.description != "" ? { Description = substr(var.description, 0, 256) } : {},
  )
  create_network      = var.delegated_subnet_id == null
  delegated_subnet_id = local.create_network ? azurerm_subnet.postgresql[0].id : var.delegated_subnet_id
  private_dns_zone_id = local.create_network ? azurerm_private_dns_zone.postgresql[0].id : var.private_dns_zone_id
}

# =============================================================================
# Resource Group
# =============================================================================
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# =============================================================================
# Network
# =============================================================================
# The server gets a private address in a subnet delegated to it and a name in
# a private DNS zone. Peer this network with the ones your workloads run in,
# or pass an existing subnet and zone instead.
resource "azurerm_virtual_network" "main" {
  count = local.create_network ? 1 : 0

  name                = "vnet-${var.name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [var.virtual_network_address_space]
  tags                = local.common_tags
}

resource "azurerm_subnet" "postgresql" {
  count = local.create_network ? 1 : 0

  name                            = "snet-postgresql"
  resource_group_name             = azurerm_resource_group.main.name
  virtual_network_name            = azurerm_virtual_network.main[0].name
  address_prefixes                = [cidrsubnet(var.virtual_network_address_space, 2, 0)]
  default_outbound_access_enabled = false

  delegation {
    name = "postgresql"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# No rules beyond the defaults: traffic from inside the virtual network and
# its peers is allowed, everything from the internet is denied.
resource "azurerm_network_security_group" "postgresql" {
  count = local.create_network ? 1 : 0

  name                = "nsg-${var.name}-${var.environment}-postgresql"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "postgresql" {
  count = local.create_network ? 1 : 0

  subnet_id                 = azurerm_subnet.postgresql[0].id
  network_security_group_id = azurerm_network_security_group.postgresql[0].id
}

resource "azurerm_private_dns_zone" "postgresql" {
  count = local.create_network ? 1 : 0

  name                = "${var.name}-${var.environment}.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  count = local.create_network ? 1 : 0

  name                = "link-${var.name}-${var.environment}"
  private_dns_zone_id = azurerm_private_dns_zone.postgresql[0].id
  virtual_network_id  = azurerm_virtual_network.main[0].id
  tags                = local.common_tags
}

# =============================================================================
# PostgreSQL Flexible Server
# =============================================================================
resource "azurerm_postgresql_flexible_server" "main" {
  #checkov:skip=CKV_AZURE_136:Geo-redundant backup is a per-environment choice (geo_redundant_backup_enabled) and is on in production
  #checkov:skip=CKV2_AZURE_57:The server is injected into a delegated subnet and has no public endpoint, which excludes a private endpoint
  name                = local.server_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  version                      = var.postgresql_version
  sku_name                     = var.sku_name
  storage_mb                   = var.storage_gb * 1024
  auto_grow_enabled            = true
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  # Private access only: the server lives in the delegated subnet.
  delegated_subnet_id           = local.delegated_subnet_id
  private_dns_zone_id           = local.private_dns_zone_id
  public_network_access_enabled = false

  # Entra ID only: there is no administrator password to store or rotate.
  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = false
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  dynamic "high_availability" {
    for_each = var.high_availability_mode == "Disabled" ? [] : [var.high_availability_mode]

    content {
      mode = high_availability.value
    }
  }

  maintenance_window {
    day_of_week  = var.maintenance_window.day_of_week
    start_hour   = var.maintenance_window.start_hour
    start_minute = var.maintenance_window.start_minute
  }

  tags = local.common_tags

  # The zone link must exist before the server registers its name.
  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql]

  lifecycle {
    # Azure swaps the primary and standby zones on failover.
    ignore_changes = [zone, high_availability[0].standby_availability_zone]
  }
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "main" {
  for_each = { for admin in var.entra_administrators : admin.object_id => admin }

  server_name         = azurerm_postgresql_flexible_server.main.name
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = each.value.object_id
  principal_name      = each.value.principal_name
  principal_type      = each.value.principal_type
}

resource "azurerm_postgresql_flexible_server_configuration" "main" {
  for_each = var.server_parameters

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = each.value
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  for_each = var.database_names

  name      = each.value
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# =============================================================================
# Diagnostic Logs
# =============================================================================
resource "azurerm_monitor_diagnostic_setting" "postgresql" {
  count = var.log_analytics_workspace_id == null ? 0 : 1

  name                       = "diag-${local.server_name}"
  target_resource_id         = azurerm_postgresql_flexible_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "PostgreSQLLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
