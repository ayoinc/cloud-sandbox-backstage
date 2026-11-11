# =============================================================================
# Azure Storage Account - Root Outputs
# =============================================================================
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.storage_account.resource_group_name
}

output "storage_account_id" {
  description = "Resource ID of the storage account"
  value       = module.storage_account.storage_account_id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage_account.storage_account_name
}

output "primary_blob_endpoint" {
  description = "URL of the blob service"
  value       = module.storage_account.primary_blob_endpoint
}

output "container_names" {
  description = "Names of the blob containers"
  value       = module.storage_account.container_names
}

output "private_endpoint_ip_address" {
  description = "Private IP address of the blob private endpoint, or null without one"
  value       = module.storage_account.private_endpoint_ip_address
}

output "encryption_identity_principal_id" {
  description = "Object ID of the identity that reads the customer-managed key, or null without one"
  value       = module.storage_account.encryption_identity_principal_id
}
