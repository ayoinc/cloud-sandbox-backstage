# The subscription and identity come from the ARM_* environment variables or
# from `az login` together with ARM_SUBSCRIPTION_ID.
provider "azurerm" {
  features {
    # Storage accounts deny public network access, so the provider must not
    # read their settings through the data plane.
    storage {
      data_plane_available = false
    }
  }
}
