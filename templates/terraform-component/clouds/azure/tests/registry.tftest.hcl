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

run "registry_has_no_admin_user" {
  command = plan

  assert {
    condition     = azurerm_container_registry.this.admin_enabled == false
    error_message = "The admin user must be disabled."
  }
}

run "rejects_unknown_sku" {
  command = plan

  variables {
    registry_sku = "Free"
  }

  expect_failures = [var.registry_sku]
}
