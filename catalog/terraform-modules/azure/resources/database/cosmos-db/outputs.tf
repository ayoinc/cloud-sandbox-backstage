# Account Outputs
output "account_id" {
  description = "The ID of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.id
}

output "account_name" {
  description = "The name of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.name
}

output "endpoint" {
  description = "The endpoint used to connect to the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "read_endpoints" {
  description = "List of read endpoints for the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.read_endpoints
}

output "write_endpoints" {
  description = "List of write endpoints for the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.write_endpoints
}

# Authentication Outputs
output "primary_key" {
  description = "The primary key for the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.primary_key
  sensitive   = true
}

output "secondary_key" {
  description = "The secondary key for the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.secondary_key
  sensitive   = true
}

output "primary_readonly_key" {
  description = "The primary read-only key for the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.primary_readonly_key
  sensitive   = true
}

output "secondary_readonly_key" {
  description = "The secondary read-only key for the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.secondary_readonly_key
  sensitive   = true
}

output "connection_strings" {
  description = "List of connection strings for the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.connection_strings
  sensitive   = true
}

output "primary_sql_connection_string" {
  description = "The primary SQL connection string for the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.primary_sql_connection_string
  sensitive   = true
}

output "secondary_sql_connection_string" {
  description = "The secondary SQL connection string for the Cosmos DB account"
  value       = azurerm_cosmosdb_account.this.secondary_sql_connection_string
  sensitive   = true
}

# Database IDs
output "database_ids" {
  description = "Map of database names to their IDs"
  value = merge(
    { for k, v in azurerm_cosmosdb_sql_database.this : k => v.id },
    { for k, v in azurerm_cosmosdb_mongo_database.this : k => v.id },
    { for k, v in azurerm_cosmosdb_cassandra_keyspace.this : k => v.id },
    { for k, v in azurerm_cosmosdb_gremlin_database.this : k => v.id },
    { for k, v in azurerm_cosmosdb_table.this : k => v.id }
  )
}

# SQL Container IDs
output "sql_container_ids" {
  description = "Map of SQL container names to their IDs"
  value       = { for k, v in azurerm_cosmosdb_sql_container.this : k => v.id }
}

# MongoDB-specific Outputs
output "mongodb_connection_string" {
  description = "The MongoDB connection string for the Cosmos DB account"
  value       = contains(var.capabilities, "EnableMongo") ? azurerm_cosmosdb_account.this.primary_mongodb_connection_string : null
  sensitive   = true
}

# Private Endpoint
output "private_endpoint_id" {
  description = "The ID of the private endpoint"
  value       = var.private_endpoint_subnet_id != null ? azurerm_private_endpoint.this[0].id : null
}

output "private_endpoint_ip_address" {
  description = "The private IP address of the private endpoint"
  value       = var.private_endpoint_subnet_id != null ? azurerm_private_endpoint.this[0].private_service_connection[0].private_ip_address : null
}

# Identity
output "identity_principal_id" {
  description = "The principal ID of the system-assigned managed identity"
  value       = var.identity_type != null ? try(azurerm_cosmosdb_account.this.identity[0].principal_id, null) : null
}

output "identity_tenant_id" {
  description = "The tenant ID of the system-assigned managed identity"
  value       = var.identity_type != null ? try(azurerm_cosmosdb_account.this.identity[0].tenant_id, null) : null
}
