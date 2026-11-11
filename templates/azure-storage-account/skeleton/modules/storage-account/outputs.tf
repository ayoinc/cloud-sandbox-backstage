# =============================================================================
# Azure Storage Account Module - Outputs
# =============================================================================
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "storage_account_id" {
  description = "Resource ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "URL of the blob service"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "container_names" {
  description = "Names of the blob containers"
  value       = sort([for container in azurerm_storage_container.main : container.name])
}

output "private_endpoint_ip_address" {
  description = "Private IP address of the blob private endpoint, or null without one"
  value       = one(azurerm_private_endpoint.blob[*].private_service_connection[0].private_ip_address)
}

output "encryption_identity_principal_id" {
  description = "Object ID of the identity that reads the customer-managed key, or null without one"
  value       = one(azurerm_user_assigned_identity.encryption[*].principal_id)
}
