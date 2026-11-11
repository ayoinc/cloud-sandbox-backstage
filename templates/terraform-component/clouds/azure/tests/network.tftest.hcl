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

run "public_and_private_subnets" {
  command = plan

  assert {
    condition     = azurerm_subnet.public.address_prefixes == tolist(["10.0.0.0/20"]) && azurerm_subnet.private.address_prefixes == tolist(["10.0.128.0/20"])
    error_message = "Subnets are /4 slices of the address space."
  }

  assert {
    condition     = azurerm_subnet.private.default_outbound_access_enabled == false
    error_message = "The private subnet must not have implicit outbound access."
  }

  assert {
    condition     = length(azurerm_nat_gateway.this) == 1
    error_message = "The private subnet gets a NAT gateway by default."
  }
}

run "nat_gateway_can_be_switched_off" {
  command = plan

  variables {
    enable_nat_gateway = false
  }

  assert {
    condition     = length(azurerm_nat_gateway.this) == 0 && length(azurerm_subnet_nat_gateway_association.private) == 0
    error_message = "No NAT gateway when it is switched off."
  }
}
