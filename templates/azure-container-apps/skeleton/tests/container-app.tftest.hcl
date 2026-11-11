# =============================================================================
# Azure Container Apps - Terraform Tests
# =============================================================================
# Run with: terraform test
# The provider is mocked: the tests need no Azure account and create nothing.
# =============================================================================

# The provider checks the format of the IDs passed between resources, so the
# mocked resources return well-formed Azure values.
mock_provider "azurerm" {
  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test-dev/providers/Microsoft.OperationalInsights/workspaces/law-test-dev"
    }
  }

  mock_resource "azurerm_container_app_environment" {
    defaults = {
      id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test-dev/providers/Microsoft.App/managedEnvironments/cae-test-dev"
      default_domain = "test.westeurope.azurecontainerapps.io"
    }
  }

  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test-dev/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-test-dev"
      principal_id = "00000000-0000-0000-0000-000000000001"
      client_id    = "00000000-0000-0000-0000-000000000002"
    }
  }

  mock_resource "azurerm_container_app" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test-dev/providers/Microsoft.App/containerApps/ca-test-dev"
    }
  }
}

variables {
  name        = "test"
  environment = "dev"
  location    = "westeurope"
  description = "Test container app"
  owner       = "platform-team"

  container_image = "mcr.microsoft.com/k8se/quickstart:latest"
  target_port     = 80
}

run "creates_app_and_environment" {
  command = apply

  assert {
    condition     = output.container_app_name == "ca-test-dev"
    error_message = "The app must be named ca-<name>-<environment>"
  }

  assert {
    condition     = output.resource_group_name == "rg-test-dev"
    error_message = "The resource group must be named rg-<name>-<environment>"
  }

  assert {
    condition     = startswith(output.container_app_url, "https://")
    error_message = "The app URL must use HTTPS"
  }

  assert {
    condition     = output.identity_client_id == "00000000-0000-0000-0000-000000000002"
    error_message = "The identity of the app must be exposed"
  }
}

run "secure_defaults" {
  command = plan

  module {
    source = "./modules/container-app"
  }

  assert {
    condition     = !azurerm_container_app.main.ingress[0].external_enabled && !azurerm_container_app.main.ingress[0].allow_insecure_connections
    error_message = "Ingress must be internal and HTTPS-only by default"
  }

  assert {
    condition     = azurerm_container_app.main.identity[0].type == "UserAssigned"
    error_message = "The app must run as a user-assigned managed identity"
  }

  assert {
    condition     = azurerm_container_app.main.template[0].min_replicas == 0 && azurerm_container_app.main.template[0].max_replicas == 3
    error_message = "The app must scale between 0 and 3 replicas by default"
  }

  assert {
    condition     = azurerm_container_app_environment.main.logs_destination == "log-analytics"
    error_message = "Container logs must go to Log Analytics"
  }

  assert {
    condition     = length(azurerm_container_app.main.registry) == 0 && length(azurerm_role_assignment.acr_pull) == 0
    error_message = "No registry access must be configured for a public image"
  }

  assert {
    condition     = azurerm_container_app.main.template[0].container[0].liveness_probe[0].port == 80
    error_message = "The probes must target the container port"
  }
}

run "private_registry_and_key_vault_secrets" {
  command = apply

  module {
    source = "./modules/container-app"
  }

  variables {
    container_image = "acrtest.azurecr.io/orders:1.4.2"
    container_registry = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-shared/providers/Microsoft.ContainerRegistry/registries/acrtest"
      login_server = "acrtest.azurecr.io"
    }
    key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-test"
    secret_environment_variables = {
      DATABASE_PASSWORD = "https://kv-test.vault.azure.net/secrets/database-password"
    }
    environment_variables = {
      LOG_LEVEL = "info"
    }
    external_ingress_enabled = true
    min_replicas             = 2
    max_replicas             = 10
  }

  assert {
    condition     = azurerm_container_app.main.registry[0].server == "acrtest.azurecr.io" && azurerm_role_assignment.acr_pull[0].role_definition_name == "AcrPull"
    error_message = "The app must pull from the registry with its identity"
  }

  assert {
    condition     = one(azurerm_container_app.main.secret[*].name) == "database-password"
    error_message = "The secret must be named after its environment variable"
  }

  assert {
    condition     = azurerm_role_assignment.key_vault_secrets_user[0].role_definition_name == "Key Vault Secrets User"
    error_message = "The identity must be allowed to read the vault's secrets"
  }

  assert {
    condition     = toset(azurerm_container_app.main.template[0].container[0].env[*].name) == toset(["AZURE_CLIENT_ID", "LOG_LEVEL", "DATABASE_PASSWORD"])
    error_message = "Plain and secret environment variables must both reach the container"
  }

  assert {
    condition     = azurerm_container_app.main.ingress[0].external_enabled
    error_message = "External ingress must follow the variable"
  }
}

run "rejects_fewer_max_than_min_replicas" {
  command = plan

  variables {
    min_replicas = 5
    max_replicas = 2
  }

  expect_failures = [var.max_replicas]
}

run "rejects_zone_redundancy_without_a_subnet" {
  command = plan

  variables {
    zone_redundancy_enabled = true
  }

  expect_failures = [var.zone_redundancy_enabled]
}
