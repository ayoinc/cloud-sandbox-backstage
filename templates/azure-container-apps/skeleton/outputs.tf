# =============================================================================
# Azure Container Apps - Root Outputs
# =============================================================================
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.container_app.resource_group_name
}

output "container_app_id" {
  description = "Resource ID of the container app"
  value       = module.container_app.container_app_id
}

output "container_app_name" {
  description = "Name of the container app"
  value       = module.container_app.container_app_name
}

output "container_app_url" {
  description = "HTTPS URL of the app; reachable from the internet only with external ingress"
  value       = module.container_app.container_app_url
}

output "latest_revision_name" {
  description = "Name of the latest revision"
  value       = module.container_app.latest_revision_name
}

output "environment_id" {
  description = "Resource ID of the Container Apps environment"
  value       = module.container_app.environment_id
}

output "environment_default_domain" {
  description = "Default domain of the Container Apps environment"
  value       = module.container_app.environment_default_domain
}

output "environment_static_ip_address" {
  description = "Static IP address of the Container Apps environment"
  value       = module.container_app.environment_static_ip_address
}

output "identity_id" {
  description = "Resource ID of the app's managed identity"
  value       = module.container_app.identity_id
}

output "identity_principal_id" {
  description = "Object ID of the app's managed identity, for role assignments"
  value       = module.container_app.identity_principal_id
}

output "identity_client_id" {
  description = "Client ID of the app's managed identity"
  value       = module.container_app.identity_client_id
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace holding the container logs"
  value       = module.container_app.log_analytics_workspace_id
}
