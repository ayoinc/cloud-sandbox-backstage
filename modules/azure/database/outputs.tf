# Azure Database Module - Outputs

output "postgresql_server_ids" {
  description = "Map of PostgreSQL Flexible Server names to their IDs"
  value       = { for k, v in azurerm_postgresql_flexible_server.this : k => v.id }
}

output "postgresql_server_fqdns" {
  description = "Map of PostgreSQL Flexible Server names to their FQDNs"
  value       = { for k, v in azurerm_postgresql_flexible_server.this : k => v.fqdn }
}

output "postgresql_server_administrator_logins" {
  description = "Map of PostgreSQL Flexible Server names to their administrator logins"
  value       = { for k, v in azurerm_postgresql_flexible_server.this : k => v.administrator_login }
  sensitive   = true
}

output "postgresql_database_ids" {
  description = "Map of PostgreSQL database keys to their IDs"
  value       = { for k, v in azurerm_postgresql_flexible_server_database.this : k => v.id }
}

output "postgresql_private_dns_zone_id" {
  description = "ID of the PostgreSQL private DNS zone (if created)"
  value       = var.create_postgresql_private_dns_zone ? azurerm_private_dns_zone.postgresql[0].id : null
}

output "postgresql_private_dns_zone_name" {
  description = "Name of the PostgreSQL private DNS zone (if created)"
  value       = var.create_postgresql_private_dns_zone ? azurerm_private_dns_zone.postgresql[0].name : null
}
