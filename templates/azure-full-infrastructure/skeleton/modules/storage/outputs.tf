output "storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_dfs_endpoint" {
  description = "Primary Data Lake endpoint (null without the hierarchical namespace)"
  value       = var.enable_hierarchical_namespace ? azurerm_storage_account.main.primary_dfs_endpoint : null
}

output "replication_type" {
  description = "Replication type of the account"
  value       = azurerm_storage_account.main.account_replication_type
}
