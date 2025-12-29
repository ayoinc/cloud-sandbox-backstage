output "topic_id" {
  description = "The ID of the Pub/Sub topic"
  value       = google_pubsub_topic.this.id
}

output "topic_name" {
  description = "The name of the Pub/Sub topic"
  value       = google_pubsub_topic.this.name
}

output "subscription_ids" {
  description = "Map of subscription names to their IDs"
  value       = { for k, v in google_pubsub_subscription.this : k => v.id }
}

output "subscription_paths" {
  description = "Map of subscription names to their full resource paths"
  value       = { for k, v in google_pubsub_subscription.this : k => v.path }
}

output "schema_id" {
  description = "The ID of the Pub/Sub schema (if created)"
  value       = var.schema_name != null && var.schema_definition != null ? google_pubsub_schema.this[0].id : null
}
