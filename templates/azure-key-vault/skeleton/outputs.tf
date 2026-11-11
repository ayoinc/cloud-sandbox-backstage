# =============================================================================
# Azure Key Vault - Root Outputs
# =============================================================================
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.key_vault.resource_group_name
}

output "key_vault_id" {
  description = "Resource ID of the key vault"
  value       = module.key_vault.key_vault_id
}

output "key_vault_name" {
  description = "Name of the key vault"
  value       = module.key_vault.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the key vault, for SDKs and secret references"
  value       = module.key_vault.key_vault_uri
}

output "tenant_id" {
  description = "Entra ID tenant that authenticates requests to the vault"
  value       = module.key_vault.tenant_id
}

output "private_endpoint_ip_address" {
  description = "Private IP address of the private endpoint, or null without one"
  value       = module.key_vault.private_endpoint_ip_address
}
