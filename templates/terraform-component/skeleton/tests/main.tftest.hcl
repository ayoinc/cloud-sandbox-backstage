# Terraform Component Tests
# Uses mock_provider for testing without credentials

# Mock providers for all supported clouds
mock_provider "azurerm" {}
mock_provider "aws" {}
mock_provider "google" {}

root_module {
  source = "../infrastructure"

  variables {
    environment = "test"
    region      = "eastus"
    project_name = "test-project"
    component_name = "test-component"
    
    tags = {
      Environment = "test"
      Project     = "test-project"
    }
  }
}

run "validate_resource_group" {
  command = plan

  assert {
    condition     = length(module.resource_group) > 0
    error_message = "Resource group module should be defined"
  }

  assert {
    condition     = module.resource_group.name == "test-project-test-rg"
    error_message = "Resource group name should be properly formatted"
  }
}

run "validate_tags" {
  command = plan

  assert {
    condition     = length(module.resource_group.tags) > 0
    error_message = "Tags should be applied to resource group"
  }

  assert {
    condition     = module.resource_group.tags.Environment == "test"
    error_message = "Environment tag should be set correctly"
  }
}