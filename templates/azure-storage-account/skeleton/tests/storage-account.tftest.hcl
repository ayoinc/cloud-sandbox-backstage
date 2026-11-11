# =============================================================================
# Azure Storage Account - Terraform Tests
# =============================================================================
# Run with: terraform test
# The provider is mocked: the tests need no Azure account and create nothing.
# =============================================================================

# The provider checks the format of the IDs passed between resources, so the
# mocked resources return well-formed Azure resource IDs.
mock_provider "azurerm" {
  mock_resource "azurerm_storage_account" {
    defaults = {
      id                    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/sttestdev"
      primary_blob_endpoint = "https://sttestdev.blob.core.windows.net/"
    }
  }

  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-test"
      principal_id = "00000000-0000-0000-0000-000000000001"
    }
  }
}

variables {
  name        = "test"
  environment = "dev"
  location    = "westeurope"
  description = "Test storage account"
  owner       = "platform-team"

  container_names = ["data", "exports"]
}

run "secure_defaults" {
  command = apply

  assert {
    condition     = output.storage_account_name == "sttestdev"
    error_message = "The account name must be st<name><environment> without hyphens"
  }

  assert {
    condition     = output.resource_group_name == "rg-test-dev"
    error_message = "The resource group must be named rg-<name>-<environment>"
  }

  assert {
    condition     = output.container_names == tolist(["data", "exports"])
    error_message = "Every requested container must be created"
  }

  assert {
    condition     = output.private_endpoint_ip_address == null && output.encryption_identity_principal_id == null
    error_message = "Private endpoint and customer-managed key must be opt-in"
  }
}

run "locked_down_by_default" {
  command = plan

  module {
    source = "./modules/storage-account"
  }

  assert {
    condition     = !azurerm_storage_account.main.shared_access_key_enabled && !azurerm_storage_account.main.allow_nested_items_to_be_public
    error_message = "Shared keys and anonymous access must be disabled"
  }

  assert {
    condition     = azurerm_storage_account.main.public_network_access == "Disabled" && azurerm_storage_account.main.network_rules[0].default_action == "Deny"
    error_message = "The account must not be reachable from the internet by default"
  }

  assert {
    condition     = azurerm_storage_account.main.min_tls_version == "TLS1_2" && azurerm_storage_account.main.infrastructure_encryption_enabled
    error_message = "TLS 1.2 and infrastructure encryption must be on"
  }

  assert {
    condition     = azurerm_storage_account.main.blob_properties[0].versioning_enabled && azurerm_storage_account.main.blob_properties[0].delete_retention_policy[0].days == 30
    error_message = "Versioning and 30 days of soft delete must be on by default"
  }

  assert {
    condition     = alltrue([for container in azurerm_storage_container.main : container.container_access_type == "private"])
    error_message = "Containers must be private"
  }

  assert {
    condition     = length(azurerm_storage_management_policy.main.rule) == 2
    error_message = "The lifecycle policy must tier blobs and expire previous versions"
  }
}

run "private_endpoint_and_customer_managed_key" {
  command = apply

  module {
    source = "./modules/storage-account"
  }

  variables {
    private_endpoint_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/endpoints"
    private_dns_zone_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-logs/providers/Microsoft.OperationalInsights/workspaces/law-test"
    customer_managed_key = {
      key_vault_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-keys/providers/Microsoft.KeyVault/vaults/kv-test"
      key_vault_key_id = "https://kv-test.vault.azure.net/keys/storage"
    }
    blob_data_reader_principal_ids = ["00000000-0000-0000-0000-000000000009"]
  }

  assert {
    condition     = length(azurerm_private_endpoint.blob) == 1 && azurerm_private_endpoint.blob[0].private_service_connection[0].subresource_names == tolist(["blob"])
    error_message = "A blob private endpoint must be created when a subnet is given"
  }

  assert {
    condition     = azurerm_storage_account.main.customer_managed_key[0].key_vault_key_id == "https://kv-test.vault.azure.net/keys/storage"
    error_message = "The account must be encrypted with the given key"
  }

  assert {
    condition     = azurerm_role_assignment.encryption[0].role_definition_name == "Key Vault Crypto Service Encryption User"
    error_message = "The encryption identity must be granted the key"
  }

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.blob) == 1 && length(azurerm_role_assignment.blob_data_reader) == 1
    error_message = "Logs and data access must follow the variables"
  }
}

run "lifecycle_without_tiering" {
  command = plan

  module {
    source = "./modules/storage-account"
  }

  variables {
    cool_after_days = null
  }

  assert {
    condition     = length(azurerm_storage_management_policy.main.rule) == 1
    error_message = "Only the previous-version rule must remain when tiering is off"
  }
}

run "rejects_archive_on_zone_redundant_storage" {
  command = plan

  module {
    source = "./modules/storage-account"
  }

  variables {
    replication_type   = "ZRS"
    archive_after_days = 180
  }

  expect_failures = [var.archive_after_days]
}

run "rejects_a_name_that_is_too_long" {
  command = plan

  module {
    source = "./modules/storage-account"
  }

  variables {
    name = "a-very-long-storage-account-name"
  }

  expect_failures = [azurerm_storage_account.main]
}
