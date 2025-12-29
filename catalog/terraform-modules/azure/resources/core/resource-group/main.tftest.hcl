# Terraform native tests for Azure Resource Group module

variables {
  project_name = "test-project"
  environment  = "test"
  location     = "eastus"

  tags = {
    Test = "true"
  }
}

run "resource_group_creation" {
  command = plan

  assert {
    condition     = azurerm_resource_group.main.location == "eastus"
    error_message = "Resource group location should be eastus"
  }
}

run "naming_convention" {
  command = plan

  assert {
    condition     = can(regex("^rg-", azurerm_resource_group.main.name))
    error_message = "Resource group name should follow naming convention (rg- prefix)"
  }
}

run "tags_applied" {
  command = plan

  assert {
    condition     = azurerm_resource_group.main.tags["Environment"] == "test"
    error_message = "Environment tag should be set"
  }

  assert {
    condition     = azurerm_resource_group.main.tags["Project"] == "test-project"
    error_message = "Project tag should be set"
  }
}
