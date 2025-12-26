# -----------------------------------------------------------------------------
# Azure Database Module - Outputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# PostgreSQL Server Outputs
# -----------------------------------------------------------------------------

output "postgresql_server_id" {
  description = "The ID of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "postgresql_server_name" {
  description = "The name of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgresql_server_fqdn" {
  description = "The FQDN of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
  sensitive   = true
}

output "postgresql_server_version" {
  description = "The PostgreSQL version"
  value       = azurerm_postgresql_flexible_server.main.version
}

# -----------------------------------------------------------------------------
# PostgreSQL Database Outputs
# -----------------------------------------------------------------------------

output "database_id" {
  description = "The ID of the PostgreSQL database"
  value       = azurerm_postgresql_flexible_server_database.main.id
}

output "database_name" {
  description = "The name of the PostgreSQL database"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

# -----------------------------------------------------------------------------
# Authentication Outputs
# -----------------------------------------------------------------------------

output "admin_username" {
  description = "The administrator username for PostgreSQL"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
  sensitive   = true
}

output "password_secret_id" {
  description = "The Key Vault secret ID containing the admin password"
  value       = azurerm_key_vault_secret.postgresql_admin_password.id
}

output "password_secret_name" {
  description = "The Key Vault secret name containing the admin password"
  value       = azurerm_key_vault_secret.postgresql_admin_password.name
}

output "connection_string_secret_id" {
  description = "The Key Vault secret ID containing the connection string"
  value       = azurerm_key_vault_secret.postgresql_connection_string.id
}

# -----------------------------------------------------------------------------
# Private DNS Zone Outputs
# -----------------------------------------------------------------------------

output "private_dns_zone_id" {
  description = "The ID of the PostgreSQL private DNS zone"
  value       = azurerm_private_dns_zone.postgresql.id
}

output "private_dns_zone_name" {
  description = "The name of the PostgreSQL private DNS zone"
  value       = azurerm_private_dns_zone.postgresql.name
}

# -----------------------------------------------------------------------------
# Private Endpoint Outputs
# -----------------------------------------------------------------------------

output "private_endpoint_id" {
  description = "The ID of the PostgreSQL private endpoint (if created)"
  value       = var.create_private_endpoint ? azurerm_private_endpoint.postgresql[0].id : null
}

output "private_endpoint_ip" {
  description = "The private IP address of the PostgreSQL private endpoint (if created)"
  value       = var.create_private_endpoint ? azurerm_private_endpoint.postgresql[0].private_service_connection[0].private_ip_address : null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Redis Cache Outputs
# -----------------------------------------------------------------------------

output "redis_id" {
  description = "The ID of the Azure Redis Cache (if enabled)"
  value       = var.enable_redis ? azurerm_redis_cache.main[0].id : null
}

output "redis_name" {
  description = "The name of the Azure Redis Cache (if enabled)"
  value       = var.enable_redis ? azurerm_redis_cache.main[0].name : null
}

output "redis_hostname" {
  description = "The hostname of the Azure Redis Cache (if enabled)"
  value       = var.enable_redis ? azurerm_redis_cache.main[0].hostname : null
  sensitive   = true
}

output "redis_port" {
  description = "The SSL port of the Azure Redis Cache (if enabled)"
  value       = var.enable_redis ? azurerm_redis_cache.main[0].ssl_port : null
}

output "redis_primary_key_secret_id" {
  description = "The Key Vault secret ID containing the Redis primary key (if enabled)"
  value       = var.enable_redis ? azurerm_key_vault_secret.redis_primary_key[0].id : null
}

output "redis_connection_string_secret_id" {
  description = "The Key Vault secret ID containing the Redis connection string (if enabled)"
  value       = var.enable_redis ? azurerm_key_vault_secret.redis_connection_string[0].id : null
}

output "redis_private_endpoint_id" {
  description = "The ID of the Redis private endpoint (if enabled and Premium SKU)"
  value       = var.enable_redis && var.redis_sku == "Premium" ? azurerm_private_endpoint.redis[0].id : null
}

output "redis_private_endpoint_ip" {
  description = "The private IP address of the Redis private endpoint (if enabled and Premium SKU)"
  value       = var.enable_redis && var.redis_sku == "Premium" ? azurerm_private_endpoint.redis[0].private_service_connection[0].private_ip_address : null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Firewall Rule Outputs
# -----------------------------------------------------------------------------

output "firewall_rule_ids" {
  description = "Map of firewall rule names to their IDs"
  value       = { for k, v in azurerm_postgresql_flexible_server_firewall_rule.rules : k => v.id }
}

# -----------------------------------------------------------------------------
# Connection Information (for convenience)
# -----------------------------------------------------------------------------

output "connection_info" {
  description = "Connection information for the PostgreSQL server"
  value = {
    host     = azurerm_postgresql_flexible_server.main.fqdn
    port     = 5432
    database = var.database_name
    username = var.admin_username
    ssl_mode = "require"
  }
  sensitive = true
}
