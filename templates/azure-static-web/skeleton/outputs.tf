output "static_web_app_id" {
  description = "Static Web App ID"
  value       = azurerm_static_web_app.main.id
}

output "default_hostname" {
  description = "Default hostname of the Static Web App"
  value       = azurerm_static_web_app.main.default_host_name
}

output "api_key" {
  description = "API key for deployment (sensitive)"
  value       = azurerm_static_web_app.main.api_key
  sensitive   = true
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "url" {
  description = "URL of the Static Web App"
  value       = "https://${azurerm_static_web_app.main.default_host_name}"
}
