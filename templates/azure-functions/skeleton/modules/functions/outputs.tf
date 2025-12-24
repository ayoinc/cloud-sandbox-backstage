# =============================================================================
# Azure Functions Module - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Resource Group Outputs
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# -----------------------------------------------------------------------------
# Function App Outputs
# -----------------------------------------------------------------------------

output "function_app_id" {
  description = "Function App ID"
  value       = azurerm_linux_function_app.main.id
}

output "function_app_name" {
  description = "Function App name"
  value       = azurerm_linux_function_app.main.name
}

output "default_hostname" {
  description = "Default hostname of the Function App"
  value       = azurerm_linux_function_app.main.default_hostname
}

output "url" {
  description = "Full URL of the Function App"
  value       = "https://${azurerm_linux_function_app.main.default_hostname}"
}

output "outbound_ip_addresses" {
  description = "Outbound IP addresses of the Function App"
  value       = azurerm_linux_function_app.main.outbound_ip_addresses
}

output "possible_outbound_ip_addresses" {
  description = "Possible outbound IP addresses of the Function App"
  value       = azurerm_linux_function_app.main.possible_outbound_ip_addresses
}

output "principal_id" {
  description = "Principal ID of the Function App managed identity"
  value       = azurerm_linux_function_app.main.identity[0].principal_id
}

output "tenant_id" {
  description = "Tenant ID of the Function App managed identity"
  value       = azurerm_linux_function_app.main.identity[0].tenant_id
}

# -----------------------------------------------------------------------------
# Storage Account Outputs
# -----------------------------------------------------------------------------

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_primary_connection_string" {
  description = "Primary connection string of the storage account"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

# -----------------------------------------------------------------------------
# Service Plan Outputs
# -----------------------------------------------------------------------------

output "service_plan_id" {
  description = "ID of the service plan"
  value       = azurerm_service_plan.main.id
}

output "service_plan_name" {
  description = "Name of the service plan"
  value       = azurerm_service_plan.main.name
}

# -----------------------------------------------------------------------------
# Application Insights Outputs
# -----------------------------------------------------------------------------

output "app_insights_id" {
  description = "Application Insights ID (null if not enabled)"
  value       = var.enable_app_insights ? azurerm_application_insights.main[0].id : null
}

output "app_insights_name" {
  description = "Application Insights name (null if not enabled)"
  value       = var.enable_app_insights ? azurerm_application_insights.main[0].name : null
}

output "app_insights_connection_string" {
  description = "Application Insights connection string (null if not enabled)"
  value       = var.enable_app_insights ? azurerm_application_insights.main[0].connection_string : null
  sensitive   = true
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key (null if not enabled)"
  value       = var.enable_app_insights ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------

output "function_app_info" {
  description = "Summary of Function App configuration"
  value = {
    name             = azurerm_linux_function_app.main.name
    id               = azurerm_linux_function_app.main.id
    resource_group   = azurerm_resource_group.main.name
    location         = azurerm_resource_group.main.location
    sku_tier         = var.sku_tier
    runtime_stack    = var.runtime_stack
    runtime_version  = var.runtime_version
    default_hostname = azurerm_linux_function_app.main.default_hostname
    url              = "https://${azurerm_linux_function_app.main.default_hostname}"
    storage_account  = azurerm_storage_account.main.name
    app_insights     = var.enable_app_insights ? azurerm_application_insights.main[0].name : null
    managed_identity = azurerm_linux_function_app.main.identity[0].principal_id
  }
}
