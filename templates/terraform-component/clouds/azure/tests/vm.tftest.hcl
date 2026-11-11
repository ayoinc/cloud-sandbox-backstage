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
  auto_shutdown_schedule    = null
  create_resource_container = true
  resource_group_name       = null
}

run "machine_is_private_and_key_only" {
  command = plan

  assert {
    condition     = azurerm_linux_virtual_machine.this.disable_password_authentication
    error_message = "The machine must accept SSH keys only."
  }

  assert {
    condition     = azurerm_network_interface.vm.ip_configuration[0].public_ip_address_id == null
    error_message = "The machine must not have a public IP address."
  }

  assert {
    condition     = length(azurerm_dev_test_global_vm_shutdown_schedule.this) == 0
    error_message = "No shutdown schedule unless auto_shutdown_schedule is set."
  }
}

run "shutdown_schedule_outside_production" {
  command = plan

  variables {
    auto_shutdown_schedule = "5 19 * * 1-5"
  }

  assert {
    condition     = azurerm_dev_test_global_vm_shutdown_schedule.this[0].daily_recurrence_time == "1905"
    error_message = "The cron minute and hour become the daily shutdown time."
  }
}

run "production_is_never_shut_down" {
  command = plan

  variables {
    environment            = "production"
    auto_shutdown_schedule = "0 19 * * 1-5"
  }

  assert {
    condition     = length(azurerm_dev_test_global_vm_shutdown_schedule.this) == 0
    error_message = "Production machines must not be stopped on a schedule."
  }
}
