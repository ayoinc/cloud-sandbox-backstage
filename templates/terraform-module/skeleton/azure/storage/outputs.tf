# -----------------------------------------------------------------------------
# Azure Storage Module - Outputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Storage Account Outputs
# -----------------------------------------------------------------------------

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_location" {
  description = "The location of the storage account"
  value       = azurerm_storage_account.main.location
}

# -----------------------------------------------------------------------------
# Endpoint Outputs
# -----------------------------------------------------------------------------

output "primary_blob_endpoint" {
  description = "The primary blob endpoint URL"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_file_endpoint" {
  description = "The primary file endpoint URL"
  value       = azurerm_storage_account.main.primary_file_endpoint
}

output "primary_queue_endpoint" {
  description = "The primary queue endpoint URL"
  value       = azurerm_storage_account.main.primary_queue_endpoint
}

output "primary_table_endpoint" {
  description = "The primary table endpoint URL"
  value       = azurerm_storage_account.main.primary_table_endpoint
}

output "primary_web_endpoint" {
  description = "The primary web endpoint URL"
  value       = azurerm_storage_account.main.primary_web_endpoint
}

# -----------------------------------------------------------------------------
# Access Keys (Sensitive)
# -----------------------------------------------------------------------------

output "primary_access_key" {
  description = "The primary access key for the storage account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "The secondary access key for the storage account"
  value       = azurerm_storage_account.main.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "The primary connection string for the storage account"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Container Outputs
# -----------------------------------------------------------------------------

output "container_ids" {
  description = "Map of container names to their IDs"
  value       = { for k, v in azurerm_storage_container.main : k => v.id }
}

output "container_names" {
  description = "List of created container names"
  value       = [for k, v in azurerm_storage_container.main : v.name]
}

# -----------------------------------------------------------------------------
# File Share Outputs
# -----------------------------------------------------------------------------

output "file_share_id" {
  description = "The ID of the file share (if enabled)"
  value       = var.enable_file_share ? azurerm_storage_share.main[0].id : null
}

output "file_share_name" {
  description = "The name of the file share (if enabled)"
  value       = var.enable_file_share ? azurerm_storage_share.main[0].name : null
}

output "file_share_url" {
  description = "The URL of the file share (if enabled)"
  value       = var.enable_file_share ? azurerm_storage_share.main[0].url : null
}
