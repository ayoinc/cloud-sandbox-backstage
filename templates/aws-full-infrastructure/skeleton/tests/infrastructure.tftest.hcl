mock_provider "azurerm" {}

variables {
  environment = "dev"
  location    = "eastus"
}

run "resource_group_created" {
  command = plan
  assert {
    condition     = azurerm_resource_group.main.name != ""
    error_message = "Resource group name should not be empty"
  }
  assert {
    condition     = azurerm_resource_group.main.location == "eastus"
    error_message = "Resource group should be in eastus"
  }
}

run "tags_applied" {
  command = plan
  assert {
    condition     = azurerm_resource_group.main.tags["environment"] == "dev"
    error_message = "Environment tag should be dev"
  }
  assert {
    condition     = azurerm_resource_group.main.tags["managed_by"] == "terraform"
    error_message = "managed_by tag should be terraform"
  }
}
