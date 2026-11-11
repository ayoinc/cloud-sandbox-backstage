terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0, < 4.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0, < 5.0.0"
    }
  }

  # The resource group and storage account of the state are supplied at init time:
  # terraform init -backend-config="resource_group_name=<group>" -backend-config="storage_account_name=<account>"
  backend "azurerm" {
    container_name   = "tfstate"
    key              = "${{ values.projectName }}/${{ values.environment }}/three-tier.tfstate"
    use_oidc         = true
    use_azuread_auth = true
  }
}

# The subscription is taken from ARM_SUBSCRIPTION_ID, or from the Azure CLI login when that is not set.
provider "azurerm" {
  features {}
}
