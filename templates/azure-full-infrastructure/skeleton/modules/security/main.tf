# =============================================================================
# Security Module
# =============================================================================
# Key Vault with Azure RBAC authorization, soft delete and purge protection.
# =============================================================================

data "azurerm_client_config" "current" {}

#trivy:ignore:AZU-0013 The vault accepts requests from any network by default so the pipeline can manage it; every request still needs an Azure role. Set restrict_network_access to change it
resource "azurerm_key_vault" "main" {
  #checkov:skip=CKV_AZURE_109:The vault accepts requests from any network by default so the pipeline can manage it; set restrict_network_access to change it
  #checkov:skip=CKV2_AZURE_32:Workloads reach the vault through the Microsoft.KeyVault service endpoint of their subnet
  name                = "kv-${var.name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Access is granted with Azure role assignments, not access policies
  enable_rbac_authorization = true

  # A deleted vault stays recoverable for 90 days and cannot be purged earlier;
  # creating it again restores it
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  network_acls {
    default_action             = var.restrict_network_access ? "Deny" : "Allow"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = var.allowed_subnet_ids
    ip_rules                   = var.allowed_ip_ranges
  }

  tags = var.tags
}
