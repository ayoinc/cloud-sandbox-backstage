# =============================================================================
# Azure AKS - Provider Configuration
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

    log_analytics_workspace {
      permanently_delete_on_destroy = false
    }
  }

  # Subscription ID from Backstage template
  subscription_id = "${{ values.subscriptionId }}"

  # Skip provider registration if not needed
  skip_provider_registration = true
}
