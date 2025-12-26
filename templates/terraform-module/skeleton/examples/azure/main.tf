# ==============================================================================
# Azure Example - Complete Deployment
# ==============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Use the root module
module "infrastructure" {
  source = "../../"

  environment               = var.environment
  project_name              = var.project_name
  azure_location            = var.azure_location
  azure_resource_group_name = var.azure_resource_group_name
  azure_vnet_cidr           = var.azure_vnet_cidr

  # Enable desired modules
  enable_compute       = true
  enable_network       = true
  enable_storage       = true
  enable_database      = false
  enable_security      = true
  enable_observability = true
  enable_kubernetes    = false
  enable_serverless    = false

  tags = var.tags
}
