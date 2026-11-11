# =============================================================================
# Azure Storage Account - Backend Configuration
# =============================================================================
# Terraform state is stored in Azure Storage.
# Backend values are provided with -backend-config flags.
# =============================================================================

terraform {
  backend "azurerm" {
    # terraform init \
    #   -backend-config="resource_group_name=rg-terraform-state" \
    #   -backend-config="storage_account_name=<storage-account>" \
    #   -backend-config="container_name=tfstate" \
    #   -backend-config="key=<project>/<environment>/terraform.tfstate"
    use_azuread_auth = true
  }
}
