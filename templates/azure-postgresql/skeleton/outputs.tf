# =============================================================================
# Azure Database for PostgreSQL - Root Outputs
# =============================================================================
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.postgresql.resource_group_name
}

output "server_id" {
  description = "Resource ID of the PostgreSQL server"
  value       = module.postgresql.server_id
}

output "server_name" {
  description = "Name of the PostgreSQL server"
  value       = module.postgresql.server_name
}

output "server_fqdn" {
  description = "Host name of the server, resolvable inside the linked virtual networks"
  value       = module.postgresql.server_fqdn
}

output "database_names" {
  description = "Names of the databases"
  value       = module.postgresql.database_names
}

output "administrator_names" {
  description = "Entra ID principals that administer the server; sign in with one of these as the user name"
  value       = module.postgresql.administrator_names
}

output "virtual_network_id" {
  description = "Resource ID of the virtual network created for the server, or null when an existing subnet is used"
  value       = module.postgresql.virtual_network_id
}

output "delegated_subnet_id" {
  description = "Resource ID of the subnet the server lives in"
  value       = module.postgresql.delegated_subnet_id
}

output "private_dns_zone_id" {
  description = "Resource ID of the private DNS zone holding the server name"
  value       = module.postgresql.private_dns_zone_id
}
