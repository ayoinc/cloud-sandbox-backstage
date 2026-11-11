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
  secondary_region          = null
  create_resource_container = true
  resource_group_name       = null
}

run "account_is_private_and_tls_only" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.min_tls_version == "TLS1_2" && azurerm_storage_account.this.https_traffic_only_enabled
    error_message = "The storage account must accept TLS 1.2 over HTTPS only."
  }

  assert {
    condition     = azurerm_storage_account.this.allow_nested_items_to_be_public == false && azurerm_storage_account.this.network_rules[0].default_action == "Deny"
    error_message = "The storage account must not be public."
  }

  assert {
    condition     = length(azurerm_storage_account.replica) == 0 && length(azurerm_storage_object_replication.this) == 0
    error_message = "No replica without a secondary region."
  }
}

run "secondary_region_adds_a_replica" {
  command = plan

  variables {
    secondary_region = "westus2"
  }

  assert {
    condition     = azurerm_storage_account.replica[0].location == "westus2"
    error_message = "The replica account is created in the secondary region."
  }

  assert {
    condition     = length(azurerm_storage_object_replication.this) == 1
    error_message = "A secondary region must add object replication."
  }
}
