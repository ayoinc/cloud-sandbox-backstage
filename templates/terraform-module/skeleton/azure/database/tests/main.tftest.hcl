mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "11111111-1111-1111-1111-111111111111"
      object_id       = "22222222-2222-2222-2222-222222222222"
      client_id       = "33333333-3333-3333-3333-333333333333"
      subscription_id = "44444444-4444-4444-4444-444444444444"
    }
  }
}

mock_provider "random" {}

variables {
  project_name        = "demo-platform-services"
  environment         = "dev"
  location            = "eastus2"
  resource_group_name = "demo-dev-rg"
  subnet_id           = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.Network/virtualNetworks/demo-vnet/subnets/database"
}

run "defaults" {
  command = plan

  assert {
    condition     = azurerm_postgresql_flexible_server.main.version == "17" && azurerm_postgresql_flexible_server.main.sku_name == "B_Standard_B1ms"
    error_message = "The server must default to PostgreSQL 17 on a burstable SKU."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.main.public_network_access_enabled == false && azurerm_postgresql_flexible_server.main.delegated_subnet_id == var.subnet_id
    error_message = "The server must be private and joined to the delegated subnet."
  }

  assert {
    condition     = azurerm_private_dns_zone.postgresql.name == "demo-platform-services-dev.private.postgres.database.azure.com"
    error_message = "The private DNS zone must use the derived name."
  }

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.postgresql.virtual_network_id == "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.Network/virtualNetworks/demo-vnet"
    error_message = "The virtual network must be derived from the subnet ID."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.main.authentication[0].password_auth_enabled && azurerm_postgresql_flexible_server.main.authentication[0].active_directory_auth_enabled == false
    error_message = "Password authentication only by default."
  }

  assert {
    condition     = length(azurerm_postgresql_flexible_server.main.high_availability) == 0 && azurerm_postgresql_flexible_server.main.geo_redundant_backup_enabled == false
    error_message = "High availability and geo backups are off by default."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server_configuration.configs["require_secure_transport"].value == "on"
    error_message = "TLS must be required."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server_database.main.name == "appdb"
    error_message = "The default database must be created."
  }

  assert {
    condition     = length(azurerm_key_vault_secret.postgresql_admin_password) == 0 && length(azurerm_managed_redis.main) == 0 && length(azurerm_private_endpoint.redis) == 0
    error_message = "Key Vault secrets and Redis are off by default."
  }
}

run "high_availability_entra_and_key_vault" {
  command = plan

  variables {
    sku_name                       = "GP_Standard_D2ds_v5"
    enable_high_availability       = true
    geo_redundant_backup           = true
    availability_zone              = "1"
    standby_availability_zone      = "2"
    enable_aad_auth                = true
    aad_administrator              = { object_id = "55555555-5555-5555-5555-555555555555", principal_name = "database-admins" }
    store_credentials_in_key_vault = true
    key_vault_id                   = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.KeyVault/vaults/kvdemo"
    secret_expiration_date         = "2030-01-01T00:00:00Z"
    maintenance_window             = { day_of_week = 0, start_hour = 2, start_minute = 0 }
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.main.high_availability[0].mode == "ZoneRedundant" && azurerm_postgresql_flexible_server.main.geo_redundant_backup_enabled
    error_message = "Zone-redundant high availability and geo backups must be configured."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.main.authentication[0].tenant_id == "11111111-1111-1111-1111-111111111111"
    error_message = "The tenant must default to the current client's tenant."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server_active_directory_administrator.main[0].principal_name == "database-admins" && azurerm_postgresql_flexible_server_active_directory_administrator.main[0].principal_type == "Group"
    error_message = "The Entra administrator must be created."
  }

  assert {
    condition     = azurerm_key_vault_secret.postgresql_admin_password[0].name == "demo-platform-services-dev-psql-admin-password" && azurerm_key_vault_secret.postgresql_connection_string[0].expiration_date == "2030-01-01T00:00:00Z"
    error_message = "Credentials must be stored in Key Vault with the expiry."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.main.maintenance_window[0].start_hour == 2
    error_message = "The maintenance window must be applied."
  }
}

run "redis" {
  command = plan

  variables {
    enable_redis               = true
    private_endpoint_subnet_id = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.Network/virtualNetworks/demo-vnet/subnets/private"
  }

  assert {
    condition     = azurerm_managed_redis.main[0].sku_name == "Balanced_B0" && azurerm_managed_redis.main[0].public_network_access == "Disabled"
    error_message = "The cache must be private."
  }

  assert {
    condition     = azurerm_managed_redis.main[0].default_database[0].client_protocol == "Encrypted" && azurerm_managed_redis.main[0].default_database[0].access_keys_authentication_enabled == false
    error_message = "The cache must be TLS-only with access keys disabled."
  }

  assert {
    condition     = azurerm_private_endpoint.redis[0].subnet_id == var.private_endpoint_subnet_id && azurerm_private_dns_zone.redis[0].name == "privatelink.redis.azure.net"
    error_message = "The cache must get a private endpoint and DNS zone."
  }

  assert {
    condition     = length(azurerm_key_vault_secret.redis_primary_key) == 0
    error_message = "No Redis key is stored when access keys are disabled."
  }
}

run "redis_keys_in_key_vault_with_existing_zone" {
  command = plan

  variables {
    enable_redis                   = true
    redis_access_keys_enabled      = true
    create_redis_private_dns_zone  = false
    redis_private_dns_zone_id      = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.redis.azure.net"
    private_endpoint_subnet_id     = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.Network/virtualNetworks/demo-vnet/subnets/private"
    store_credentials_in_key_vault = true
    key_vault_id                   = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.KeyVault/vaults/kvdemo"
  }

  assert {
    condition     = length(azurerm_private_dns_zone.redis) == 0 && azurerm_private_endpoint.redis[0].private_dns_zone_group[0].private_dns_zone_ids == tolist([var.redis_private_dns_zone_id])
    error_message = "The existing DNS zone must be used."
  }

  assert {
    condition     = length(azurerm_key_vault_secret.redis_primary_key) == 1 && length(azurerm_key_vault_secret.redis_connection_string) == 1
    error_message = "The Redis key and connection string must be stored."
  }
}

run "entra_only_authentication" {
  command = plan

  variables {
    enable_password_auth = false
    enable_aad_auth      = true
    tenant_id            = "66666666-6666-6666-6666-666666666666"
    aad_administrator    = { object_id = "55555555-5555-5555-5555-555555555555", principal_name = "ci", principal_type = "ServicePrincipal" }
  }

  assert {
    condition     = output.admin_username == null && output.connection_info.username == null
    error_message = "No password administrator is configured."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.main.authentication[0].tenant_id == "66666666-6666-6666-6666-666666666666"
    error_message = "The supplied tenant must be used."
  }
}

run "rejects_redis_without_endpoint_subnet" {
  command = plan

  variables {
    enable_redis = true
  }

  expect_failures = [azurerm_private_endpoint.redis]
}

run "rejects_high_availability_on_burstable" {
  command = plan

  variables {
    enable_high_availability = true
  }

  expect_failures = [azurerm_postgresql_flexible_server.main]
}

run "rejects_key_vault_storage_without_vault" {
  command = plan

  variables {
    store_credentials_in_key_vault = true
  }

  expect_failures = [
    azurerm_key_vault_secret.postgresql_admin_password,
    azurerm_key_vault_secret.postgresql_connection_string,
  ]
}

run "rejects_entra_without_administrator" {
  command = plan

  variables {
    enable_aad_auth = true
  }

  expect_failures = [azurerm_postgresql_flexible_server.main]
}
