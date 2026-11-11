# =============================================================================
# Azure Key Vault - Provider Configuration
# =============================================================================
# Authentication comes from the environment: ARM_CLIENT_ID, ARM_TENANT_ID and
# ARM_SUBSCRIPTION_ID with OIDC in the pipeline, or `az login` locally.
# =============================================================================

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }

    key_vault {
      # Purge protection is on: a destroyed vault stays soft-deleted, and a
      # vault of the same name is recovered rather than created empty.
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }

  # The deploying identity needs no rights to register resource providers.
  resource_provider_registrations = "none"
}
