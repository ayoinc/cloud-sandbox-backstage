# Subscription, tenant and client are read from the ARM_* environment variables.
provider "azurerm" {
  features {}
}

provider "azuread" {}
