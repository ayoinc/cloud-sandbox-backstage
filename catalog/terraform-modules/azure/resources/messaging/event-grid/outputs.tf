output "topic_id" {
  description = "The ID of the Event Grid custom topic"
  value       = var.create_custom_topic ? azurerm_eventgrid_topic.this[0].id : null
}

output "topic_endpoint" {
  description = "The endpoint of the Event Grid custom topic"
  value       = var.create_custom_topic ? azurerm_eventgrid_topic.this[0].endpoint : null
}

output "topic_primary_access_key" {
  description = "The primary access key for the Event Grid custom topic"
  value       = var.create_custom_topic ? azurerm_eventgrid_topic.this[0].primary_access_key : null
  sensitive   = true
}

output "topic_secondary_access_key" {
  description = "The secondary access key for the Event Grid custom topic"
  value       = var.create_custom_topic ? azurerm_eventgrid_topic.this[0].secondary_access_key : null
  sensitive   = true
}

output "system_topic_id" {
  description = "The ID of the Event Grid system topic"
  value       = var.create_system_topic ? azurerm_eventgrid_system_topic.this[0].id : null
}

output "system_topic_metric_arm_resource_id" {
  description = "The metric ARM resource ID for the system topic"
  value       = var.create_system_topic ? azurerm_eventgrid_system_topic.this[0].metric_arm_resource_id : null
}

output "domain_id" {
  description = "The ID of the Event Grid domain"
  value       = var.create_domain ? azurerm_eventgrid_domain.this[0].id : null
}

output "domain_endpoint" {
  description = "The endpoint of the Event Grid domain"
  value       = var.create_domain ? azurerm_eventgrid_domain.this[0].endpoint : null
}

output "domain_primary_access_key" {
  description = "The primary access key for the Event Grid domain"
  value       = var.create_domain ? azurerm_eventgrid_domain.this[0].primary_access_key : null
  sensitive   = true
}

output "domain_secondary_access_key" {
  description = "The secondary access key for the Event Grid domain"
  value       = var.create_domain ? azurerm_eventgrid_domain.this[0].secondary_access_key : null
  sensitive   = true
}

output "subscription_ids" {
  description = "Map of subscription names to their IDs"
  value = merge(
    var.create_custom_topic ? {
      for name, sub in azurerm_eventgrid_event_subscription.custom_topic : name => sub.id
    } : {},
    var.create_system_topic ? {
      for name, sub in azurerm_eventgrid_system_topic_event_subscription.this : name => sub.id
    } : {}
  )
}
