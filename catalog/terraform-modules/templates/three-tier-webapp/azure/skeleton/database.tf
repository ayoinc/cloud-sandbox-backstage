# -----------------------------------------------------------------------------
# Data tier: one of Azure SQL Database, a PostgreSQL flexible server or a
# Cosmos DB account, chosen by database_type. None of them has a public
# endpoint.
# -----------------------------------------------------------------------------

locals {
  # Ports the application subnet may reach in the data subnet.
  database_ports = {
    "sql-database" = ["1433"]
    "postgresql"   = ["5432", "6432"]
    "cosmos-db"    = ["443", "10000-20000"]
  }[var.database_type]

  database_endpoint = (
    local.uses_sql ? module.sql[0].server_fqdn :
    local.uses_postgresql ? azurerm_postgresql_flexible_server.main[0].fqdn :
    module.cosmos[0].endpoint
  )

  # The Basic tier of Azure SQL Database stores at most 2 GB.
  sql_max_size_gb = var.database_sku == "Basic" ? 2 : var.database_storage_gb

  # Burstable PostgreSQL servers cannot have a standby.
  postgresql_has_standby = local.is_production && !startswith(var.database_sku, "B_")
}

# Server and account names are unique across Azure.
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Administrator password of the SQL or PostgreSQL server. It is kept in the
# Terraform state and available as the output database_admin_password.
resource "random_password" "database" {
  count = local.uses_cosmos ? 0 : 1

  length           = 32
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#%*-_=+"
}

# --- sql-database -------------------------------------------------------------

module "sql" {
  count  = local.uses_sql ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/database/sql-database?ref=${{ values.moduleRef }}"

  resource_group_name = module.resource_group.name
  location            = var.location
  project             = var.project_name
  environment         = local.environment_short

  administrator_login    = var.database_admin_username
  administrator_password = random_password.database[0].result

  public_network_access_enabled = false
  allow_azure_services          = false

  databases = {
    (var.database_name) = {
      sku_name             = var.database_sku
      max_size_gb          = local.sql_max_size_gb
      storage_account_type = local.is_production ? "Geo" : "Local"
    }
  }

  tags = local.common_tags
}

resource "azurerm_private_dns_zone" "sql" {
  count = local.uses_sql ? 1 : 0

  name                = "privatelink.database.windows.net"
  resource_group_name = module.resource_group.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  count = local.uses_sql ? 1 : 0

  name                  = "vnet"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.sql[0].name
  virtual_network_id    = module.network.vnet_id
  tags                  = local.common_tags
}

# The private endpoint registers the server in the private DNS zone, so its
# usual name resolves to the private address inside the virtual network.
resource "azurerm_private_endpoint" "sql" {
  count = local.uses_sql ? 1 : 0

  name                = "pe-sql-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = module.network.subnet_ids["data"]

  private_service_connection {
    name                           = "sql"
    private_connection_resource_id = module.sql[0].server_id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql[0].id]
  }

  tags = local.common_tags
}

# --- postgresql ---------------------------------------------------------------

resource "azurerm_private_dns_zone" "postgresql" {
  count = local.uses_postgresql ? 1 : 0

  name                = "${local.name_prefix}.private.postgres.database.azure.com"
  resource_group_name = module.resource_group.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  count = local.uses_postgresql ? 1 : 0

  name                  = "vnet"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql[0].name
  virtual_network_id    = module.network.vnet_id
  tags                  = local.common_tags
}

resource "azurerm_postgresql_flexible_server" "main" {
  count = local.uses_postgresql ? 1 : 0

  name                = "psql-${local.name_prefix}-${random_string.suffix.result}"
  resource_group_name = module.resource_group.name
  location            = var.location
  version             = var.postgresql_version
  sku_name            = var.database_sku
  storage_mb          = var.database_storage_gb * 1024
  auto_grow_enabled   = true

  delegated_subnet_id           = module.network.subnet_ids["data"]
  private_dns_zone_id           = azurerm_private_dns_zone.postgresql[0].id
  public_network_access_enabled = false

  administrator_login    = var.database_admin_username
  administrator_password = random_password.database[0].result

  backup_retention_days        = local.is_production ? 35 : 7
  geo_redundant_backup_enabled = local.is_production

  dynamic "high_availability" {
    for_each = local.postgresql_has_standby ? ["ZoneRedundant"] : []

    content {
      mode = high_availability.value
    }
  }

  tags = local.common_tags

  # Azure chooses the availability zones and swaps them on a failover. Remove
  # prevent_destroy to delete the server and its data on purpose.
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [zone, high_availability[0].standby_availability_zone]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql]
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  count = local.uses_postgresql ? 1 : 0

  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main[0].id
  charset   = "UTF8"
  collation = "en_US.utf8"

  lifecycle {
    prevent_destroy = true
  }
}

# --- cosmos-db ----------------------------------------------------------------

resource "azurerm_private_dns_zone" "cosmos" {
  count = local.uses_cosmos ? 1 : 0

  name                = "privatelink.documents.azure.com"
  resource_group_name = module.resource_group.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos" {
  count = local.uses_cosmos ? 1 : 0

  name                  = "vnet"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos[0].name
  virtual_network_id    = module.network.vnet_id
  tags                  = local.common_tags
}

module "cosmos" {
  count  = local.uses_cosmos ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/database/cosmos-db?ref=${{ values.moduleRef }}"

  project_name        = var.project_name
  environment         = local.environment_short
  resource_group_name = module.resource_group.name
  location            = var.location
  account_name        = "cosmos-${local.name_prefix}-${random_string.suffix.result}"

  geo_locations = [
    {
      location          = var.location
      failover_priority = 0
    }
  ]

  enable_automatic_failover = false
  capabilities              = var.database_sku == "serverless" ? ["EnableServerless"] : []
  backup_storage_redundancy = local.is_production ? "Geo" : "Local"

  databases = [
    {
      name                     = var.database_name
      autoscale_max_throughput = var.database_sku == "autoscale" ? var.cosmos_max_throughput : null
    }
  ]

  public_network_access_enabled = false

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "cosmos" {
  count = local.uses_cosmos ? 1 : 0

  name                = "pe-cosmos-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = module.network.subnet_ids["data"]

  private_service_connection {
    name                           = "cosmos"
    private_connection_resource_id = module.cosmos[0].account_id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmos[0].id]
  }

  tags = local.common_tags
}
