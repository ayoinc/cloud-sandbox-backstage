# =============================================================================
# Azure VNet - Backend Configuration
# =============================================================================
# Azure Storage backend for Terraform state.
# Backend values are provided via CLI -backend-config flags.
# =============================================================================

terraform {
  backend "azurerm" {
    # Backend configuration provided via CLI:
    # terraform init \
    #   -backend-config="resource_group_name=rg-terraform-state" \
    #   -backend-config="storage_account_name=stterraformstate" \
    #   -backend-config="container_name=tfstate" \
    #   -backend-config="key=<project>/<environment>/terraform.tfstate"
  }
}
