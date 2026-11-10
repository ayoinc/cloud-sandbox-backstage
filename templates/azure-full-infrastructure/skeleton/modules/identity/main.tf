# =============================================================================
# Identity Module
# =============================================================================
# User-assigned managed identity for workloads, optionally allowed to read
# secrets from the Key Vault.
# =============================================================================

resource "azurerm_user_assigned_identity" "main" {
  name                = "id-${var.name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  count = var.grant_key_vault_access ? 1 : 0

  scope                            = var.key_vault_id
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = azurerm_user_assigned_identity.main.principal_id
  skip_service_principal_aad_check = true
}
