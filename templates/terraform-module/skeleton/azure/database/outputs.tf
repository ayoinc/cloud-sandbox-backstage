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
}

output "postgresql_server_version" {
  description = "The PostgreSQL version"
  value       = var.postgresql_version
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
  description = "The administrator username for PostgreSQL (null when password authentication is disabled)"
  value       = var.enable_password_auth ? var.admin_username : null
}

output "admin_password" {
  description = "The generated administrator password for PostgreSQL (null when password authentication is disabled)"
  value       = var.enable_password_auth ? random_password.postgresql_admin.result : null
  sensitive   = true
}

output "password_secret_id" {
  description = "The Key Vault secret ID containing the admin password (null unless credentials are stored in Key Vault)"
  value       = one(azurerm_key_vault_secret.postgresql_admin_password[*].id)
}

output "password_secret_name" {
  description = "The Key Vault secret name containing the admin password (null unless credentials are stored in Key Vault)"
  value       = one(azurerm_key_vault_secret.postgresql_admin_password[*].name)
}

output "connection_string_secret_id" {
  description = "The Key Vault secret ID containing the connection string (null unless credentials are stored in Key Vault)"
  value       = one(azurerm_key_vault_secret.postgresql_connection_string[*].id)
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
# Azure Managed Redis Outputs
# -----------------------------------------------------------------------------

output "redis_id" {
  description = "The ID of the Azure Managed Redis cache (if enabled)"
  value       = one(azurerm_managed_redis.main[*].id)
}

output "redis_name" {
  description = "The name of the Azure Managed Redis cache (if enabled)"
  value       = one(azurerm_managed_redis.main[*].name)
}

output "redis_hostname" {
  description = "The hostname of the Azure Managed Redis cache (if enabled)"
  value       = one(azurerm_managed_redis.main[*].hostname)
}

output "redis_port" {
  description = "The TLS port of the Azure Managed Redis database (if enabled)"
  value       = var.enable_redis ? azurerm_managed_redis.main[0].default_database[0].port : null
}

output "redis_primary_key_secret_id" {
  description = "The Key Vault secret ID containing the Redis primary key (if stored)"
  value       = one(azurerm_key_vault_secret.redis_primary_key[*].id)
}

output "redis_connection_string_secret_id" {
  description = "The Key Vault secret ID containing the Redis connection string (if stored)"
  value       = one(azurerm_key_vault_secret.redis_connection_string[*].id)
}

output "redis_private_endpoint_id" {
  description = "The ID of the Redis private endpoint (if enabled)"
  value       = one(azurerm_private_endpoint.redis[*].id)
}

output "redis_private_endpoint_ip" {
  description = "The private IP address of the Redis private endpoint (if enabled)"
  value       = var.enable_redis ? azurerm_private_endpoint.redis[0].private_service_connection[0].private_ip_address : null
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
    username = var.enable_password_auth ? var.admin_username : null
    ssl_mode = "require"
  }
}
