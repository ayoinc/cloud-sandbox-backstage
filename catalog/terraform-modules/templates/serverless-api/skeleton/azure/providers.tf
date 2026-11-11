provider "azurerm" {
  # An empty value leaves the subscription to the ARM_SUBSCRIPTION_ID
  # environment variable.
  subscription_id = var.subscription_id != "" ? var.subscription_id : null

  features {}
}
