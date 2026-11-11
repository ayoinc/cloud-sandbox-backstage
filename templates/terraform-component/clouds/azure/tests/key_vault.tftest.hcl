# Plan-only tests against mocked providers: no credentials, no resources.

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "00000000-0000-0000-0000-000000000000"
      subscription_id = "11111111-1111-1111-1111-111111111111"
      object_id       = "22222222-2222-2222-2222-222222222222"
    }
  }
}

mock_provider "tls" {}

mock_provider "random" {
  mock_resource "random_id" {
    defaults = {
      hex = "ab12cd34"
    }
  }
}

# Every variable is set here so that the tests do not depend on terraform.tfvars.
variables {
  component_name            = "test-component"
  component_type            = "application"
  project_name              = "billing"
  environment               = "development"
  business_unit             = "engineering"
  cost_center               = "application-development"
  application_id            = ""
  owner                     = "group:default/platform-team"
  company                   = "example-org"
  naming_convention         = "enterprise"
  region                    = "eastus"
  create_resource_container = true
  resource_group_name       = null
}

run "vault_is_locked_down" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this.purge_protection_enabled && azurerm_key_vault.this.rbac_authorization_enabled
    error_message = "The vault must use purge protection and role-based access."
  }

  assert {
    condition     = azurerm_key_vault.this.network_acls[0].default_action == "Deny"
    error_message = "The vault must deny network access by default."
  }

  assert {
    condition     = azurerm_key_vault.this.soft_delete_retention_days == 7
    error_message = "Outside production deleted items are kept for 7 days."
  }
}

run "production_keeps_deleted_items_longer" {
  command = plan

  variables {
    environment = "production"
  }

  assert {
    condition     = azurerm_key_vault.this.soft_delete_retention_days == 90
    error_message = "In production deleted items are kept for 90 days."
  }
}
