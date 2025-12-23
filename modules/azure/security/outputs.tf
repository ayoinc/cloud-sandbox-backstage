# Azure Security Module - Outputs

output "key_vault_ids" {
  description = "Map of Key Vault names to their IDs"
  value       = { for k, v in azurerm_key_vault.this : k => v.id }
}

output "key_vault_uris" {
  description = "Map of Key Vault names to their URIs"
  value       = { for k, v in azurerm_key_vault.this : k => v.vault_uri }
}

output "key_vault_tenant_id" {
  description = "Tenant ID used for the Key Vaults"
  value       = data.azurerm_client_config.current.tenant_id
}

output "key_vault_secret_ids" {
  description = "Map of Key Vault secret names to their IDs"
  value       = { for k, v in azurerm_key_vault_secret.this : k => v.id }
}

output "key_vault_secret_versions" {
  description = "Map of Key Vault secret names to their versions"
  value       = { for k, v in azurerm_key_vault_secret.this : k => v.version }
}

output "key_vault_key_ids" {
  description = "Map of Key Vault key names to their IDs"
  value       = { for k, v in azurerm_key_vault_key.this : k => v.id }
}

output "key_vault_key_versionless_ids" {
  description = "Map of Key Vault key names to their versionless IDs"
  value       = { for k, v in azurerm_key_vault_key.this : k => v.versionless_id }
}

output "user_assigned_identity_ids" {
  description = "Map of User Assigned Identity names to their IDs"
  value       = { for k, v in azurerm_user_assigned_identity.this : k => v.id }
}

output "user_assigned_identity_principal_ids" {
  description = "Map of User Assigned Identity names to their Principal IDs"
  value       = { for k, v in azurerm_user_assigned_identity.this : k => v.principal_id }
}

output "user_assigned_identity_client_ids" {
  description = "Map of User Assigned Identity names to their Client IDs"
  value       = { for k, v in azurerm_user_assigned_identity.this : k => v.client_id }
}

output "private_endpoint_ids" {
  description = "Map of Private Endpoint names to their IDs"
  value       = { for k, v in azurerm_private_endpoint.key_vault : k => v.id }
}

output "private_endpoint_private_ips" {
  description = "Map of Private Endpoint names to their private IP addresses"
  value       = { for k, v in azurerm_private_endpoint.key_vault : k => v.private_service_connection[0].private_ip_address }
}
