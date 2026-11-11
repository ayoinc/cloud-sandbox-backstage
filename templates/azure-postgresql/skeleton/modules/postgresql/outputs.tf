# =============================================================================
# Azure Database for PostgreSQL Module - Outputs
# =============================================================================
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "server_id" {
  description = "Resource ID of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "server_fqdn" {
  description = "Host name of the server, resolvable inside the linked virtual networks"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "database_names" {
  description = "Names of the databases"
  value       = sort([for database in azurerm_postgresql_flexible_server_database.main : database.name])
}

output "administrator_names" {
  description = "Entra ID principals that administer the server; sign in with one of these as the user name"
  value       = sort([for admin in azurerm_postgresql_flexible_server_active_directory_administrator.main : admin.principal_name])
}

output "virtual_network_id" {
  description = "Resource ID of the virtual network created for the server, or null when an existing subnet is used"
  value       = one(azurerm_virtual_network.main[*].id)
}

output "delegated_subnet_id" {
  description = "Resource ID of the subnet the server lives in"
  value       = local.delegated_subnet_id
}

output "private_dns_zone_id" {
  description = "Resource ID of the private DNS zone holding the server name"
  value       = local.private_dns_zone_id
}
