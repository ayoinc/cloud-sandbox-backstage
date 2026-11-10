# =============================================================================
# Azure AKS - Provider Configuration
# =============================================================================
# Authentication comes from the environment: ARM_CLIENT_ID, ARM_TENANT_ID and
# ARM_SUBSCRIPTION_ID with OIDC in the pipeline, or `az login` locally.
# =============================================================================

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    log_analytics_workspace {
      permanently_delete_on_destroy = false
    }
  }

  # The deploying identity needs no rights to register resource providers.
  skip_provider_registration = true
}
