# =============================================================================
# Azure Database for PostgreSQL - Terraform Tests
# =============================================================================
# Run with: terraform test
# The provider is mocked: the tests need no Azure account and create nothing.
# =============================================================================

# The provider checks the format of the IDs passed between resources, so the
# mocked resources return well-formed Azure values.
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-00000000000a"
      object_id = "00000000-0000-0000-0000-00000000000b"
    }
  }

  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test-dev/providers/Microsoft.Network/virtualNetworks/vnet-test-dev"
    }
  }

  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test-dev/providers/Microsoft.Network/virtualNetworks/vnet-test-dev/subnets/snet-postgresql"
    }
  }

  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test-dev/providers/Microsoft.Network/networkSecurityGroups/nsg-test-dev-postgresql"
    }
  }

  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test-dev/providers/Microsoft.Network/privateDnsZones/test-dev.private.postgres.database.azure.com"
    }
  }

  mock_resource "azurerm_postgresql_flexible_server" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test-dev/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-test-dev"
      fqdn = "psql-test-dev.test-dev.private.postgres.database.azure.com"
    }
  }
}

variables {
  name        = "test"
  environment = "dev"
  location    = "westeurope"
  description = "Test PostgreSQL server"
  owner       = "platform-team"

  database_names = ["app"]
  entra_administrators = [
    {
      object_id      = "00000000-0000-0000-0000-000000000001"
      principal_name = "database-admins"
      principal_type = "Group"
    },
  ]
}

run "creates_server_network_and_database" {
  command = apply

  assert {
    condition     = output.server_name == "psql-test-dev"
    error_message = "The server must be named psql-<name>-<environment>"
  }

  assert {
    condition     = output.resource_group_name == "rg-test-dev"
    error_message = "The resource group must be named rg-<name>-<environment>"
  }

  assert {
    condition     = output.database_names == tolist(["app"])
    error_message = "The requested database must be created"
  }

  assert {
    condition     = output.administrator_names == tolist(["database-admins"])
    error_message = "The Entra ID administrator must be set"
  }

  assert {
    condition     = output.virtual_network_id != null
    error_message = "A virtual network must be created when no subnet is given"
  }
}

run "private_and_passwordless" {
  command = plan

  module {
    source = "./modules/postgresql"
  }

  assert {
    condition     = !azurerm_postgresql_flexible_server.main.public_network_access_enabled
    error_message = "The server must have no public endpoint"
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.main.authentication[0].active_directory_auth_enabled && !azurerm_postgresql_flexible_server.main.authentication[0].password_auth_enabled
    error_message = "Entra ID must be the only authentication method"
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.main.storage_mb == 32768 && azurerm_postgresql_flexible_server.main.auto_grow_enabled
    error_message = "Storage must be given in GiB and grow automatically"
  }

  assert {
    condition     = length(azurerm_postgresql_flexible_server.main.high_availability) == 0
    error_message = "High availability must be off by default"
  }

  assert {
    condition     = azurerm_subnet.postgresql[0].address_prefixes == tolist(["10.60.0.0/26"])
    error_message = "The delegated subnet must be the first quarter of the address space"
  }

  assert {
    condition     = azurerm_subnet.postgresql[0].delegation[0].service_delegation[0].name == "Microsoft.DBforPostgreSQL/flexibleServers"
    error_message = "The subnet must be delegated to PostgreSQL flexible servers"
  }

  assert {
    condition     = azurerm_postgresql_flexible_server_configuration.main["connection_throttle.enable"].value == "on"
    error_message = "Connection throttling must be on by default"
  }
}

run "zone_redundant_on_an_existing_network" {
  command = apply

  module {
    source = "./modules/postgresql"
  }

  variables {
    postgresql_version           = "18"
    sku_name                     = "GP_Standard_D4ds_v5"
    storage_gb                   = 128
    high_availability_mode       = "ZoneRedundant"
    backup_retention_days        = 35
    geo_redundant_backup_enabled = true
    delegated_subnet_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/snet-postgresql"
    private_dns_zone_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/privateDnsZones/hub.private.postgres.database.azure.com"
    log_analytics_workspace_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-logs/providers/Microsoft.OperationalInsights/workspaces/law-test"
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.main.high_availability[0].mode == "ZoneRedundant"
    error_message = "A zone-redundant standby must be configured"
  }

  assert {
    condition     = length(azurerm_virtual_network.main) == 0 && length(azurerm_private_dns_zone.postgresql) == 0
    error_message = "No network must be created when a subnet is given"
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.main.delegated_subnet_id == var.delegated_subnet_id
    error_message = "The server must use the given subnet"
  }

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.postgresql) == 1
    error_message = "Logs must be sent to the workspace"
  }
}

run "rejects_high_availability_on_burstable" {
  command = plan

  variables {
    sku_name               = "B_Standard_B2s"
    high_availability_mode = "ZoneRedundant"
  }

  expect_failures = [var.high_availability_mode]
}

run "rejects_a_subnet_without_a_dns_zone" {
  command = plan

  variables {
    delegated_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/snet-postgresql"
  }

  expect_failures = [var.private_dns_zone_id]
}
