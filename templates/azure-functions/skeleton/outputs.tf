# =============================================================================
# Azure Functions - Root Outputs
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.functions.resource_group_name
}

output "function_app_id" {
  description = "Function App ID"
  value       = module.functions.function_app_id
}

output "function_app_name" {
  description = "Function App name"
  value       = module.functions.function_app_name
}

output "default_hostname" {
  description = "Default hostname"
  value       = module.functions.default_hostname
}

output "url" {
  description = "Full URL of the Function App"
  value       = module.functions.url
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.functions.storage_account_name
}

output "storage_account_primary_connection_string" {
  description = "Primary connection string of the storage account"
  value       = module.functions.storage_account_primary_connection_string
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "Application Insights connection string"
  value       = module.functions.app_insights_connection_string
  sensitive   = true
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = module.functions.app_insights_instrumentation_key
  sensitive   = true
}

output "principal_id" {
  description = "Principal ID of the Function App managed identity"
  value       = module.functions.principal_id
}

output "function_app_info" {
  description = "Summary of Function App configuration"
  value       = module.functions.function_app_info
}
