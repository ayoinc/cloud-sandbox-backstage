# =============================================================================
# Azure Key Vault Module - Outputs
# =============================================================================
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "key_vault_id" {
  description = "Resource ID of the key vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Name of the key vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the key vault, for SDKs and secret references"
  value       = azurerm_key_vault.main.vault_uri
}

output "tenant_id" {
  description = "Entra ID tenant that authenticates requests to the vault"
  value       = azurerm_key_vault.main.tenant_id
}

output "private_endpoint_ip_address" {
  description = "Private IP address of the private endpoint, or null without one"
  value       = one(azurerm_private_endpoint.vault[*].private_service_connection[0].private_ip_address)
}
