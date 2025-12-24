# =============================================================================
# Azure VNet - Provider Configuration
# =============================================================================
# AzureRM provider configuration.
# Authentication is handled via environment variables or OIDC.
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }

    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
  }

  # Subscription ID from Backstage template
  subscription_id = "${{ values.subscriptionId }}"

  # Optional: Skip provider registration if not needed
  skip_provider_registration = true

  # Storage configuration for data operations
  storage_use_azuread = true
}
