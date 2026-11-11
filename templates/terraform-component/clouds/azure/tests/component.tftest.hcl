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

run "names_and_tags_follow_the_conventions" {
  command = plan

  assert {
    condition     = azurerm_resource_group.this[0].name == "example-org-billing-dev-rg-001"
    error_message = "The enterprise convention is company-project-env-type-instance."
  }

  assert {
    condition     = azurerm_resource_group.this[0].tags["Component"] == "test-component" && azurerm_resource_group.this[0].tags["CostCenter"] == "application-development"
    error_message = "Resources carry the standard tags."
  }
}

run "project_naming_convention" {
  command = plan

  variables {
    naming_convention = "project"
  }

  assert {
    condition     = azurerm_resource_group.this[0].name == "billing-rg-dev-001"
    error_message = "The project convention is project-type-env-instance."
  }
}

run "existing_resource_group" {
  command = plan

  variables {
    create_resource_container = false
    resource_group_name       = "shared-rg"
  }

  assert {
    condition     = length(azurerm_resource_group.this) == 0
    error_message = "No resource group is created when an existing one is used."
  }
}

run "existing_resource_group_needs_a_name" {
  command = plan

  variables {
    create_resource_container = false
  }

  expect_failures = [data.azurerm_resource_group.existing]
}
