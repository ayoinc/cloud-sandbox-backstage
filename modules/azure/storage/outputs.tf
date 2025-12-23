# Azure Storage Module - Outputs

output "storage_account_ids" {
  description = "Map of Storage Account names to their IDs"
  value       = { for k, v in azurerm_storage_account.this : k => v.id }
}

output "storage_account_primary_endpoints" {
  description = "Map of Storage Account names to their primary blob endpoints"
  value       = { for k, v in azurerm_storage_account.this : k => v.primary_blob_endpoint }
}

output "storage_account_primary_access_keys" {
  description = "Map of Storage Account names to their primary access keys"
  value       = { for k, v in azurerm_storage_account.this : k => v.primary_access_key }
  sensitive   = true
}

output "storage_account_primary_connection_strings" {
  description = "Map of Storage Account names to their primary connection strings"
  value       = { for k, v in azurerm_storage_account.this : k => v.primary_connection_string }
  sensitive   = true
}

output "storage_account_identity_principal_ids" {
  description = "Map of Storage Account names to their managed identity principal IDs"
  value       = { for k, v in azurerm_storage_account.this : k => try(v.identity[0].principal_id, null) }
}

output "storage_container_ids" {
  description = "Map of Storage Container names to their IDs"
  value       = { for k, v in azurerm_storage_container.this : k => v.id }
}

output "storage_share_ids" {
  description = "Map of Storage Share names to their IDs"
  value       = { for k, v in azurerm_storage_share.this : k => v.id }
}

output "storage_share_urls" {
  description = "Map of Storage Share names to their URLs"
  value       = { for k, v in azurerm_storage_share.this : k => v.url }
}

output "storage_queue_ids" {
  description = "Map of Storage Queue names to their IDs"
  value       = { for k, v in azurerm_storage_queue.this : k => v.id }
}

output "storage_table_ids" {
  description = "Map of Storage Table names to their IDs"
  value       = { for k, v in azurerm_storage_table.this : k => v.id }
}
