output "store_url" {
  description = "Address of the store."
  value       = var.enable_cdn ? "https://${azurerm_cdn_frontdoor_endpoint.main[0].host_name}" : "https://${azurerm_container_app.frontend.ingress[0].fqdn}"
}

output "frontend_url" {
  description = "Address of the storefront container app, behind the content delivery network."
  value       = "https://${azurerm_container_app.frontend.ingress[0].fqdn}"
}

output "database_host" {
  description = "Host name of the PostgreSQL server."
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "admin_token" {
  description = "Bearer token of the admin API."
  value       = random_password.admin_token.result
  sensitive   = true
}
