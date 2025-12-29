output "application_gateway_id" {
  description = "The ID of the Application Gateway"
  value       = azurerm_application_gateway.this.id
}

output "application_gateway_name" {
  description = "The name of the Application Gateway"
  value       = azurerm_application_gateway.this.name
}

output "backend_address_pool_ids" {
  description = "The IDs of the backend address pools"
  value       = { for pool in azurerm_application_gateway.this.backend_address_pool : pool.name => pool.id }
}

output "frontend_ip_configuration_id" {
  description = "The ID of the frontend IP configuration"
  value       = azurerm_application_gateway.this.frontend_ip_configuration[0].id
}
