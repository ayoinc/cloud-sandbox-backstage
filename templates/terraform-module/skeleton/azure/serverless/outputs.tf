# -----------------------------------------------------------------------------
# Azure Serverless Module - Outputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Function App Outputs
# -----------------------------------------------------------------------------

output "function_app_id" {
  description = "The ID of the Linux Function App"
  value       = azurerm_linux_function_app.main.id
}

output "function_app_name" {
  description = "The name of the Linux Function App"
  value       = azurerm_linux_function_app.main.name
}

output "function_app_default_hostname" {
  description = "The default hostname of the Linux Function App"
  value       = azurerm_linux_function_app.main.default_hostname
}

output "function_app_outbound_ip_addresses" {
  description = "Comma-separated list of outbound IP addresses"
  value       = azurerm_linux_function_app.main.outbound_ip_addresses
}

output "function_app_possible_outbound_ip_addresses" {
  description = "Comma-separated list of possible outbound IP addresses"
  value       = azurerm_linux_function_app.main.possible_outbound_ip_addresses
}

# -----------------------------------------------------------------------------
# Identity Outputs
# -----------------------------------------------------------------------------

output "function_app_identity_principal_id" {
  description = "Principal ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.function.principal_id
}

output "function_app_identity_client_id" {
  description = "Client ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.function.client_id
}

output "function_app_identity_id" {
  description = "ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.function.id
}

# -----------------------------------------------------------------------------
# Service Plan Outputs
# -----------------------------------------------------------------------------

output "service_plan_id" {
  description = "The ID of the App Service Plan"
  value       = azurerm_service_plan.function.id
}

output "service_plan_name" {
  description = "The name of the App Service Plan"
  value       = azurerm_service_plan.function.name
}

# -----------------------------------------------------------------------------
# Storage Account Outputs
# -----------------------------------------------------------------------------

output "storage_account_id" {
  description = "The ID of the Storage Account"
  value       = azurerm_storage_account.function.id
}

output "storage_account_name" {
  description = "The name of the Storage Account"
  value       = azurerm_storage_account.function.name
}

output "storage_account_primary_blob_endpoint" {
  description = "The primary blob endpoint of the Storage Account"
  value       = azurerm_storage_account.function.primary_blob_endpoint
}

# -----------------------------------------------------------------------------
# Application Insights Outputs
# -----------------------------------------------------------------------------

output "application_insights_id" {
  description = "The ID of the Application Insights instance (null if using external)"
  value       = var.application_insights_connection_string == null ? azurerm_application_insights.function[0].id : null
}

output "application_insights_connection_string" {
  description = "The connection string for Application Insights"
  value       = local.application_insights_connection_string
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "The instrumentation key for Application Insights"
  value       = local.application_insights_key
  sensitive   = true
}

# -----------------------------------------------------------------------------
# API Management Outputs (Conditional)
# -----------------------------------------------------------------------------

output "api_management_id" {
  description = "The ID of the API Management instance"
  value       = var.enable_api_management ? azurerm_api_management.main[0].id : null
}

output "api_management_name" {
  description = "The name of the API Management instance"
  value       = var.enable_api_management ? azurerm_api_management.main[0].name : null
}

output "api_management_gateway_url" {
  description = "The gateway URL of the API Management instance"
  value       = var.enable_api_management ? azurerm_api_management.main[0].gateway_url : null
}

output "api_management_gateway_regional_url" {
  description = "The regional gateway URL of the API Management instance"
  value       = var.enable_api_management ? azurerm_api_management.main[0].gateway_regional_url : null
}

output "api_management_developer_portal_url" {
  description = "The developer portal URL of the API Management instance"
  value       = var.enable_api_management ? azurerm_api_management.main[0].developer_portal_url : null
}

output "api_management_api_id" {
  description = "The ID of the API in API Management"
  value       = var.enable_api_management ? azurerm_api_management_api.function[0].id : null
}

# -----------------------------------------------------------------------------
# Service Bus Outputs (Conditional)
# -----------------------------------------------------------------------------

output "service_bus_namespace_id" {
  description = "The ID of the Service Bus namespace"
  value       = var.enable_service_bus ? azurerm_servicebus_namespace.main[0].id : null
}

output "service_bus_namespace_name" {
  description = "The name of the Service Bus namespace"
  value       = var.enable_service_bus ? azurerm_servicebus_namespace.main[0].name : null
}

output "service_bus_namespace_endpoint" {
  description = "The endpoint of the Service Bus namespace"
  value       = var.enable_service_bus ? azurerm_servicebus_namespace.main[0].endpoint : null
}

output "service_bus_queue_id" {
  description = "The ID of the Service Bus queue"
  value       = var.enable_service_bus ? azurerm_servicebus_queue.main[0].id : null
}

output "service_bus_queue_name" {
  description = "The name of the Service Bus queue"
  value       = var.enable_service_bus ? azurerm_servicebus_queue.main[0].name : null
}

# -----------------------------------------------------------------------------
# Event Grid Outputs (Conditional)
# -----------------------------------------------------------------------------

output "event_grid_topic_id" {
  description = "The ID of the Event Grid topic"
  value       = var.enable_event_grid ? azurerm_eventgrid_topic.main[0].id : null
}

output "event_grid_topic_endpoint" {
  description = "The endpoint of the Event Grid topic"
  value       = var.enable_event_grid ? azurerm_eventgrid_topic.main[0].endpoint : null
}

output "event_grid_topic_primary_access_key" {
  description = "The primary access key for the Event Grid topic"
  value       = var.enable_event_grid ? azurerm_eventgrid_topic.main[0].primary_access_key : null
  sensitive   = true
}
