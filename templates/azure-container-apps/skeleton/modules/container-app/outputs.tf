# =============================================================================
# Azure Container Apps Module - Outputs
# =============================================================================
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "container_app_id" {
  description = "Resource ID of the container app"
  value       = azurerm_container_app.main.id
}

output "container_app_name" {
  description = "Name of the container app"
  value       = azurerm_container_app.main.name
}

output "container_app_url" {
  description = "HTTPS URL of the app; reachable from the internet only with external ingress"
  value       = "https://${azurerm_container_app.main.ingress[0].fqdn}"
}

output "latest_revision_name" {
  description = "Name of the latest revision"
  value       = azurerm_container_app.main.latest_revision_name
}

output "environment_id" {
  description = "Resource ID of the Container Apps environment"
  value       = azurerm_container_app_environment.main.id
}

output "environment_default_domain" {
  description = "Default domain of the Container Apps environment"
  value       = azurerm_container_app_environment.main.default_domain
}

output "environment_static_ip_address" {
  description = "Static IP address of the Container Apps environment"
  value       = azurerm_container_app_environment.main.static_ip_address
}

output "identity_id" {
  description = "Resource ID of the app's managed identity"
  value       = azurerm_user_assigned_identity.app.id
}

output "identity_principal_id" {
  description = "Object ID of the app's managed identity, for role assignments"
  value       = azurerm_user_assigned_identity.app.principal_id
}

output "identity_client_id" {
  description = "Client ID of the app's managed identity"
  value       = azurerm_user_assigned_identity.app.client_id
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace holding the container logs"
  value       = azurerm_log_analytics_workspace.main.id
}
