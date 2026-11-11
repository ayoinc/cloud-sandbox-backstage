# -----------------------------------------------------------------------------
# Key management: Key Vault for keys, secrets and certificates
# -----------------------------------------------------------------------------

variable "key_vault_allowed_ips" {
  description = "Public IP addresses or CIDR ranges allowed to reach the Key Vault. Azure services are always allowed; everything else is denied."
  type        = list(string)
  default     = []
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = module.naming.global_compact["kv"]
  resource_group_name = local.resource_group_name
  location            = var.region
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Access is granted with Azure role assignments, not access policies.
  rbac_authorization_enabled = true

  purge_protection_enabled   = true
  soft_delete_retention_days = var.environment == "production" ? 90 : 7

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.key_vault_allowed_ips
  }

  tags = module.tagging.tags
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault."
  value       = azurerm_key_vault.this.vault_uri
}
