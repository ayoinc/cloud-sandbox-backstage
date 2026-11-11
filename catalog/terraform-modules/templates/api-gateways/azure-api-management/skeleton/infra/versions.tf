terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.81.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.10.0"
    }
  }

  # Storage account, container and key are passed with -backend-config by the
  # Deploy workflow.
  backend "azurerm" {}
}
