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
    time = {
      source  = "hashicorp/time"
      version = ">= 0.11.0, < 1.0.0"
    }
  }

  # The resource group and storage account of the state are supplied at init time:
  # terraform init -backend-config="resource_group_name=<group>" -backend-config="storage_account_name=<account>"
  backend "azurerm" {
    container_name   = "tfstate"
    key              = "${{ values.projectName }}/${{ values.environment }}/data-platform.tfstate"
    use_oidc         = true
    use_azuread_auth = true
  }
}

provider "azurerm" {
  # null selects the subscription of the credentials Terraform runs with (ARM_SUBSCRIPTION_ID in the pipeline).
  subscription_id = var.subscription_id

  # With access control on, the data lake has no account keys, so its filesystems are managed with Microsoft Entra ID.
  storage_use_azuread = var.enable_access_control

  features {}
}
