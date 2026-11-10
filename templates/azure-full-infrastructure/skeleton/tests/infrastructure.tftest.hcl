# =============================================================================
# Azure Full Infrastructure - Terraform Tests
# =============================================================================
# Run against a mocked provider, so no Azure account is needed.
# Run with: terraform test
# =============================================================================

# The provider checks the format of the IDs passed between resources, so the
# mocked resources return well-formed Azure resource IDs.
mock_provider "azurerm" {
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
    }
  }

  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test"
    }
  }

  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
    }
  }

  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/networkSecurityGroups/nsg-test"
    }
  }

  mock_resource "azurerm_public_ip" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-test"
    }
  }

  mock_resource "azurerm_nat_gateway" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/natGateways/nat-test"
    }
  }

  mock_resource "azurerm_network_ddos_protection_plan" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/ddosProtectionPlans/ddos-test"
    }
  }

  mock_resource "azurerm_key_vault" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
    }
  }

  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-test"
      principal_id = "00000000-0000-0000-0000-000000000001"
      client_id    = "00000000-0000-0000-0000-000000000002"
    }
  }

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/log-test"
    }
  }

  mock_resource "azurerm_application_insights" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/components/appi-test"
    }
  }

  mock_resource "azurerm_container_registry" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerRegistry/registries/acrtest"
    }
  }

  mock_resource "azurerm_kubernetes_cluster" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/aks-test"
    }
  }

  mock_resource "azurerm_kubernetes_cluster_node_pool" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/aks-test/agentPools/user"
    }
  }

  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateDnsZones/test.private.postgres.database.azure.com"
    }
  }

  mock_resource "azurerm_postgresql_flexible_server" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-test"
    }
  }

  mock_resource "azurerm_network_interface" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/networkInterfaces/nic-test"
    }
  }

  mock_resource "azurerm_linux_virtual_machine" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Compute/virtualMachines/vm-test"
    }
  }

  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/sttest"
    }
  }

  mock_resource "azurerm_servicebus_namespace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ServiceBus/namespaces/sb-test"
    }
  }

  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "00000000-0000-0000-0000-00000000000a"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      object_id       = "00000000-0000-0000-0000-00000000000b"
    }
  }
}

# -----------------------------------------------------------------------------
# Test Variables: every module enabled
# -----------------------------------------------------------------------------
variables {
  name               = "test-stack"
  environment        = "dev"
  description        = "Test stack"
  owner              = "platform-team"
  business_unit      = "platform"
  location           = "eastus"
  secondary_location = "westus2"

  enable_networking  = true
  enable_compute     = true
  enable_containers  = true
  enable_storage     = true
  enable_database    = true
  enable_security    = true
  enable_identity    = true
  enable_monitoring  = true
  enable_integration = true
  enable_governance  = true
}

# -----------------------------------------------------------------------------
# Test: Every Module Enabled
# -----------------------------------------------------------------------------
run "all_modules_enabled" {
  command = apply

  assert {
    condition     = output.resource_group_name == "rg-test-stack-dev"
    error_message = "Primary resource group should follow convention: rg-{name}-{environment}"
  }

  assert {
    condition     = output.network_resource_group_name == "rg-test-stack-dev-network"
    error_message = "Networking should have its own resource group"
  }

  assert {
    condition     = output.vnet_name == "vnet-test-stack-dev"
    error_message = "Virtual network should follow convention: vnet-{name}-{environment}"
  }

  assert {
    condition     = length(output.subnet_ids) == 5
    error_message = "Five subnets should be created"
  }

  assert {
    condition     = output.key_vault_name == "kv-test-stack-dev"
    error_message = "Key Vault should follow convention: kv-{name}-{environment}"
  }

  assert {
    condition     = output.storage_account_name == "stteststackdev"
    error_message = "Storage account name should be st{name}{environment} without hyphens"
  }

  assert {
    condition     = output.aks_cluster_name == "aks-test-stack-dev"
    error_message = "AKS cluster should follow convention: aks-{name}-{environment}"
  }

  assert {
    condition     = output.database_name == "test_stack"
    error_message = "Database name should be the project name with underscores"
  }

  assert {
    condition     = length(output.vm_names) == 1
    error_message = "One virtual machine should be created by default"
  }

  assert {
    condition     = output.service_bus_namespace_name == "sb-test-stack-dev"
    error_message = "Service Bus namespace should follow convention: sb-{name}-{environment}"
  }

  assert {
    condition     = alltrue(values(output.infrastructure_summary.enabled_modules))
    error_message = "The summary should list every module as enabled"
  }
}

# -----------------------------------------------------------------------------
# Test: Every Module Disabled
# -----------------------------------------------------------------------------
run "all_modules_disabled" {
  command = apply

  variables {
    enable_networking  = false
    enable_compute     = false
    enable_containers  = false
    enable_storage     = false
    enable_database    = false
    enable_security    = false
    enable_identity    = false
    enable_monitoring  = false
    enable_integration = false
    enable_governance  = false
  }

  assert {
    condition     = output.resource_group_name == "rg-test-stack-dev"
    error_message = "The primary resource group is always created"
  }

  assert {
    condition     = output.vnet_id == null
    error_message = "No virtual network should be created"
  }

  assert {
    condition     = output.key_vault_id == null
    error_message = "No Key Vault should be created"
  }

  assert {
    condition     = output.storage_account_name == null
    error_message = "No storage account should be created"
  }

  assert {
    condition     = output.aks_cluster_name == null
    error_message = "No AKS cluster should be created"
  }

  assert {
    condition     = length(output.vm_names) == 0
    error_message = "No virtual machines should be created"
  }

  assert {
    condition     = !anytrue(values(output.infrastructure_summary.enabled_modules))
    error_message = "The summary should list every module as disabled"
  }
}

# -----------------------------------------------------------------------------
# Test: Modules Work Without Networking
# -----------------------------------------------------------------------------
run "modules_without_networking" {
  command = apply

  variables {
    enable_networking = false
    enable_compute    = false
  }

  assert {
    condition     = output.vnet_id == null
    error_message = "No virtual network should be created"
  }

  assert {
    condition     = output.aks_cluster_name == "aks-test-stack-dev"
    error_message = "AKS should be created in a network it manages itself"
  }

  assert {
    condition     = output.database_server_fqdn != null
    error_message = "PostgreSQL should be created with its public endpoint"
  }

  assert {
    condition     = output.key_vault_name == "kv-test-stack-dev"
    error_message = "Key Vault should be created without subnet rules"
  }
}

# -----------------------------------------------------------------------------
# Test: Compute Needs Networking
# -----------------------------------------------------------------------------
run "compute_requires_networking" {
  command = plan

  variables {
    enable_networking = false
    enable_compute    = true
  }

  expect_failures = [terraform_data.requirements]
}

# -----------------------------------------------------------------------------
# Test: Storage Replication Without HA or DR
# -----------------------------------------------------------------------------
run "locally_redundant_by_default" {
  command = apply

  assert {
    condition     = output.storage_replication_type == "LRS"
    error_message = "Storage should be locally redundant without HA and DR"
  }

  assert {
    condition     = output.acr_sku == "Standard"
    error_message = "The registry should use the Standard SKU without DR"
  }
}

# -----------------------------------------------------------------------------
# Test: High Availability
# -----------------------------------------------------------------------------
run "high_availability" {
  command = apply

  variables {
    enable_high_availability = true
    database_sku_name        = "GP_Standard_D2s_v3"
  }

  assert {
    condition     = output.storage_replication_type == "ZRS"
    error_message = "Storage should be zone redundant with HA"
  }

  assert {
    condition     = output.database_zone_redundant
    error_message = "PostgreSQL should have a zone-redundant standby with HA"
  }
}

# -----------------------------------------------------------------------------
# Test: Burstable Database Has No Standby
# -----------------------------------------------------------------------------
run "high_availability_burstable_database" {
  command = apply

  variables {
    enable_high_availability = true
    database_sku_name        = "B_Standard_B1ms"
  }

  assert {
    condition     = !output.database_zone_redundant
    error_message = "Burstable PostgreSQL servers cannot have a zone-redundant standby"
  }
}

# -----------------------------------------------------------------------------
# Test: Disaster Recovery
# -----------------------------------------------------------------------------
run "disaster_recovery" {
  command = apply

  variables {
    enable_dr = true
  }

  assert {
    condition     = output.storage_replication_type == "GRS"
    error_message = "Storage should be geo-redundant with DR"
  }

  assert {
    condition     = output.acr_sku == "Premium"
    error_message = "The registry should use the Premium SKU, which supports geo-replication"
  }
}

# -----------------------------------------------------------------------------
# Test: High Availability With Disaster Recovery
# -----------------------------------------------------------------------------
run "high_availability_and_disaster_recovery" {
  command = apply

  variables {
    enable_dr                = true
    enable_high_availability = true
  }

  assert {
    condition     = output.storage_replication_type == "GZRS"
    error_message = "Storage should be geo-zone-redundant with HA and DR"
  }
}

# -----------------------------------------------------------------------------
# Test: Auto-Shutdown Outside Production
# -----------------------------------------------------------------------------
run "auto_shutdown_outside_production" {
  command = apply

  variables {
    enable_auto_shutdown = true
  }

  assert {
    condition     = output.vm_auto_shutdown_enabled
    error_message = "Virtual machines should shut down daily in dev"
  }
}

# -----------------------------------------------------------------------------
# Test: No Auto-Shutdown In Production
# -----------------------------------------------------------------------------
run "no_auto_shutdown_in_production" {
  command = apply

  variables {
    environment          = "prod"
    enable_auto_shutdown = true
  }

  assert {
    condition     = !output.vm_auto_shutdown_enabled
    error_message = "Virtual machines should never shut down automatically in prod"
  }

  assert {
    condition     = output.resource_group_name == "rg-test-stack-prod"
    error_message = "Resource group should carry the prod environment"
  }
}

# -----------------------------------------------------------------------------
# Test: NAT Gateway, Bastion and DDoS Protection
# -----------------------------------------------------------------------------
run "optional_network_features" {
  command = apply

  # Bastion accepts only a subnet named AzureBastionSubnet.
  override_resource {
    target = module.networking[0].azurerm_subnet.bastion
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/AzureBastionSubnet"
    }
  }

  variables {
    enable_nat_gateway     = true
    enable_bastion         = true
    enable_ddos_protection = true
  }

  assert {
    condition     = output.vnet_name == "vnet-test-stack-dev"
    error_message = "The virtual network should be created with the optional features"
  }
}

# -----------------------------------------------------------------------------
# Test: Restricted Network Access
# -----------------------------------------------------------------------------
run "restricted_network_access" {
  command = apply

  variables {
    restrict_network_access = true
    allowed_ip_ranges       = ["203.0.113.10"]
  }

  assert {
    condition     = output.key_vault_name == "kv-test-stack-dev"
    error_message = "Key Vault should be created with network restrictions"
  }

  assert {
    condition     = output.storage_account_name == "stteststackdev"
    error_message = "The storage account should be created with network restrictions"
  }
}

# -----------------------------------------------------------------------------
# Test: Project Name Length
# -----------------------------------------------------------------------------
run "name_too_long" {
  command = plan

  variables {
    name = "a-name-longer-than-13"
  }

  expect_failures = [var.name]
}
