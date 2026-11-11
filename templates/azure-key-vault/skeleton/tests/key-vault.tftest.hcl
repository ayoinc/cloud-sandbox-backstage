# =============================================================================
# Azure Key Vault - Terraform Tests
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

  mock_resource "azurerm_key_vault" {
    defaults = {
      id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test-dev/providers/Microsoft.KeyVault/vaults/kv-test-dev"
      vault_uri = "https://kv-test-dev.vault.azure.net/"
    }
  }
}

variables {
  name        = "test"
  environment = "dev"
  location    = "westeurope"
  description = "Test key vault"
  owner       = "platform-team"
}

run "naming_and_outputs" {
  command = apply

  assert {
    condition     = output.key_vault_name == "kv-test-dev"
    error_message = "The vault must be named kv-<name>-<environment>"
  }

  assert {
    condition     = output.resource_group_name == "rg-test-dev"
    error_message = "The resource group must be named rg-<name>-<environment>"
  }

  assert {
    condition     = output.tenant_id == "00000000-0000-0000-0000-00000000000a"
    error_message = "The vault must belong to the tenant of the deploying identity"
  }

  assert {
    condition     = output.private_endpoint_ip_address == null
    error_message = "The private endpoint must be opt-in"
  }
}

run "secure_defaults" {
  command = plan

  module {
    source = "./modules/key-vault"
  }

  assert {
    condition     = azurerm_key_vault.main.rbac_authorization_enabled && azurerm_key_vault.main.purge_protection_enabled
    error_message = "Azure RBAC and purge protection must be on"
  }

  assert {
    condition     = azurerm_key_vault.main.soft_delete_retention_days == 90
    error_message = "Deleted objects must be recoverable for 90 days by default"
  }

  assert {
    condition     = !azurerm_key_vault.main.public_network_access_enabled && azurerm_key_vault.main.network_acls[0].default_action == "Deny"
    error_message = "The vault must not be reachable from the internet by default"
  }

  assert {
    condition     = length(azurerm_role_assignment.main) == 0
    error_message = "Nobody must get data plane access unless listed"
  }
}

run "access_private_endpoint_and_audit_log" {
  command = apply

  module {
    source = "./modules/key-vault"
  }

  variables {
    administrator_principal_ids = ["00000000-0000-0000-0000-000000000001"]
    secrets_user_principal_ids  = ["00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000003"]
    private_endpoint_subnet_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/endpoints"
    private_dns_zone_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    log_analytics_workspace_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-logs/providers/Microsoft.OperationalInsights/workspaces/law-test"
  }

  assert {
    condition     = length(azurerm_role_assignment.main) == 3
    error_message = "One role assignment per listed principal must be created"
  }

  assert {
    condition     = azurerm_role_assignment.main["Key Vault Secrets User/00000000-0000-0000-0000-000000000002"].role_definition_name == "Key Vault Secrets User"
    error_message = "Secrets users must get the Key Vault Secrets User role"
  }

  assert {
    condition     = length(azurerm_private_endpoint.vault) == 1 && azurerm_private_endpoint.vault[0].private_service_connection[0].subresource_names == tolist(["vault"])
    error_message = "A private endpoint to the vault must be created when a subnet is given"
  }

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.vault) == 1
    error_message = "The audit log must be sent to the workspace"
  }
}

run "firewall_follows_the_variables" {
  command = plan

  module {
    source = "./modules/key-vault"
  }

  variables {
    public_network_access_enabled = true
    allowed_ip_ranges             = ["203.0.113.0/24"]
    trusted_services_bypass       = false
  }

  assert {
    condition     = azurerm_key_vault.main.network_acls[0].default_action == "Deny" && azurerm_key_vault.main.network_acls[0].bypass == "None"
    error_message = "The firewall must keep denying by default when the public endpoint is on"
  }

  assert {
    condition     = contains(azurerm_key_vault.main.network_acls[0].ip_rules, "203.0.113.0/24")
    error_message = "Allowed ranges must reach the firewall"
  }
}

run "rejects_a_name_that_is_too_long" {
  command = plan

  module {
    source = "./modules/key-vault"
  }

  variables {
    name = "a-very-long-key-vault-name"
  }

  expect_failures = [azurerm_key_vault.main]
}

run "rejects_short_soft_delete_retention" {
  command = plan

  variables {
    soft_delete_retention_days = 3
  }

  expect_failures = [var.soft_delete_retention_days]
}
