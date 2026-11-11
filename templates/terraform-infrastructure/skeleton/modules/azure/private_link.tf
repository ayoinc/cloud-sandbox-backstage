# Data stores, the Key Vault and the storage accounts have no public access.
# Each gets a private endpoint in the data subnet (or the first private
# subnet of an existing network) and a private DNS zone that resolves its
# public name to that endpoint inside the virtual network.

locals {
  private_dns_zone_names = {
    blob       = "privatelink.blob.core.windows.net"
    dfs        = "privatelink.dfs.core.windows.net"
    vault      = "privatelink.vaultcore.azure.net"
    postgresql = "privatelink.postgres.database.azure.com"
    mysql      = "privatelink.mysql.database.azure.com"
    mongodb    = "privatelink.mongo.cosmos.azure.com"
    cosmosdb   = "privatelink.documents.azure.com"
    redis      = "privatelink.redis.azure.net"
  }

  database_subresources = {
    postgresql = "postgresqlServer"
    mysql      = "mysqlServer"
    mongodb    = "MongoDB"
    cosmosdb   = "Sql"
    redis      = "redisEnterprise"
  }

  private_endpoint_candidates = {
    storage = {
      enabled     = var.enable_storage
      resource_id = one(azurerm_storage_account.this[*].id)
      subresource = "blob"
      zone        = "blob"
    }
    data-lake-blob = {
      enabled     = local.data_lake_enabled
      resource_id = one(azurerm_storage_account.data_lake[*].id)
      subresource = "blob"
      zone        = "blob"
    }
    data-lake-dfs = {
      enabled     = local.data_lake_enabled
      resource_id = one(azurerm_storage_account.data_lake[*].id)
      subresource = "dfs"
      zone        = "dfs"
    }
    key-vault = {
      enabled     = local.key_vault_enabled
      resource_id = one(azurerm_key_vault.this[*].id)
      subresource = "vault"
      zone        = "vault"
    }
    database = {
      enabled     = var.enable_database
      resource_id = local.database_resource_id
      subresource = local.database_subresources[var.database_type]
      zone        = var.database_type
    }
  }

  private_endpoints = {
    for name, endpoint in local.private_endpoint_candidates : name => endpoint
    if endpoint.enabled && local.network_available
  }

  private_dns_zones = toset([for endpoint in local.private_endpoints : endpoint.zone])
}

resource "azurerm_private_dns_zone" "private_link" {
  for_each = local.private_dns_zones

  name                = local.private_dns_zone_names[each.key]
  resource_group_name = azurerm_resource_group.this.name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_link" {
  for_each = local.private_dns_zones

  name                  = "${var.name_prefix}-${each.key}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.private_link[each.key].name
  virtual_network_id    = local.network_id

  tags = local.tags
}

resource "azurerm_private_endpoint" "this" {
  for_each = local.private_endpoints

  name                = "${var.name_prefix}-${each.key}-pe"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = local.endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name_prefix}-${each.key}"
    private_connection_resource_id = each.value.resource_id
    subresource_names              = [each.value.subresource]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_link[each.value.zone].id]
  }

  tags = local.tags

  # Names must resolve in the network as soon as the endpoint exists.
  depends_on = [azurerm_private_dns_zone_virtual_network_link.private_link]
}
