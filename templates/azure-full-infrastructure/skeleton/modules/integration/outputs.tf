output "service_bus_namespace_id" {
  description = "Service Bus namespace ID"
  value       = azurerm_servicebus_namespace.main.id
}

output "service_bus_namespace_name" {
  description = "Service Bus namespace name"
  value       = azurerm_servicebus_namespace.main.name
}

output "service_bus_endpoint" {
  description = "Service Bus endpoint"
  value       = azurerm_servicebus_namespace.main.endpoint
}

output "event_grid_topic_id" {
  description = "Event Grid topic ID"
  value       = azurerm_eventgrid_topic.main.id
}

output "event_grid_topic_endpoint" {
  description = "Event Grid topic endpoint"
  value       = azurerm_eventgrid_topic.main.endpoint
}
