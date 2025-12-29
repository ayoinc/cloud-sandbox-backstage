output "environment_id" {
  description = "The ID of the Container App Environment"
  value       = azurerm_container_app_environment.this.id
}

output "container_app_id" {
  description = "The ID of the Container App"
  value       = azurerm_container_app.this.id
}

output "container_app_fqdn" {
  description = "The FQDN of the Container App"
  value       = azurerm_container_app.this.ingress[0].fqdn
}

output "latest_revision_name" {
  description = "The name of the latest revision"
  value       = azurerm_container_app.this.latest_revision_name
}
