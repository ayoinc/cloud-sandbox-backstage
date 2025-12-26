# -----------------------------------------------------------------------------
# Azure Observability Module - Outputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Log Analytics Workspace Outputs
# -----------------------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_key" {
  description = "The primary shared key of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_secondary_key" {
  description = "The secondary shared key of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.secondary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_workspace_id" {
  description = "The Workspace (or Customer) ID for the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "log_analytics_portal_url" {
  description = "The Portal URL for the Log Analytics workspace"
  value       = "https://portal.azure.com/#@/resource${azurerm_log_analytics_workspace.main.id}/logs"
}

# -----------------------------------------------------------------------------
# Application Insights Outputs
# -----------------------------------------------------------------------------

output "application_insights_id" {
  description = "The ID of the Application Insights component"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].id : null
}

output "application_insights_name" {
  description = "The name of the Application Insights component"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].name : null
}

output "application_insights_app_id" {
  description = "The App ID associated with the Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].app_id : null
}

output "instrumentation_key" {
  description = "The instrumentation key for Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}

output "connection_string" {
  description = "The connection string for Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].connection_string : null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Action Group Outputs
# -----------------------------------------------------------------------------

output "action_group_id" {
  description = "The ID of the monitor action group"
  value       = azurerm_monitor_action_group.main.id
}

output "action_group_name" {
  description = "The name of the monitor action group"
  value       = azurerm_monitor_action_group.main.name
}

# -----------------------------------------------------------------------------
# Alert Outputs
# -----------------------------------------------------------------------------

output "cpu_alert_id" {
  description = "The ID of the CPU metric alert"
  value       = var.enable_cpu_alert && var.monitored_resource_id != null ? azurerm_monitor_metric_alert.high_cpu[0].id : null
}

output "memory_alert_id" {
  description = "The ID of the memory metric alert"
  value       = var.enable_memory_alert && var.monitored_resource_id != null ? azurerm_monitor_metric_alert.high_memory[0].id : null
}

output "disk_alert_id" {
  description = "The ID of the disk metric alert"
  value       = var.enable_disk_alert && var.monitored_resource_id != null ? azurerm_monitor_metric_alert.low_disk_space[0].id : null
}

output "http_errors_alert_id" {
  description = "The ID of the HTTP errors metric alert"
  value       = var.enable_http_errors_alert && var.monitored_resource_id != null ? azurerm_monitor_metric_alert.http_errors[0].id : null
}

output "service_health_alert_id" {
  description = "The ID of the service health activity log alert"
  value       = var.enable_service_health_alert ? azurerm_monitor_activity_log_alert.service_health[0].id : null
}

# -----------------------------------------------------------------------------
# Dashboard Outputs
# -----------------------------------------------------------------------------

output "dashboard_id" {
  description = "The ID of the Azure portal dashboard"
  value       = var.enable_dashboard ? azurerm_portal_dashboard.main[0].id : null
}

output "dashboard_url" {
  description = "The URL to access the Azure portal dashboard"
  value       = var.enable_dashboard ? "https://portal.azure.com/#@/dashboard/arm${azurerm_portal_dashboard.main[0].id}" : null
}

# -----------------------------------------------------------------------------
# Container Insights Outputs
# -----------------------------------------------------------------------------

output "container_insights_solution_id" {
  description = "The ID of the Container Insights solution"
  value       = var.enable_container_insights ? azurerm_log_analytics_solution.container_insights[0].id : null
}

# -----------------------------------------------------------------------------
# Subscription Info
# -----------------------------------------------------------------------------

output "subscription_id" {
  description = "The subscription ID where resources are deployed"
  value       = data.azurerm_subscription.current.subscription_id
}
