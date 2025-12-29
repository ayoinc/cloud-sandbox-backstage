output "namespace_id" {
  description = "The ID of the Event Hub namespace"
  value       = azurerm_eventhub_namespace.this.id
}

output "namespace_name" {
  description = "The name of the Event Hub namespace"
  value       = azurerm_eventhub_namespace.this.name
}

output "default_primary_connection_string" {
  description = "The primary connection string for the Event Hub namespace"
  value       = azurerm_eventhub_namespace.this.default_primary_connection_string
  sensitive   = true
}

output "eventhub_ids" {
  description = "Map of Event Hub names to their IDs"
  value       = { for k, v in azurerm_eventhub.this : k => v.id }
}

output "consumer_group_ids" {
  description = "Map of consumer group keys to their IDs"
  value       = { for k, v in azurerm_eventhub_consumer_group.this : k => v.id }
}
