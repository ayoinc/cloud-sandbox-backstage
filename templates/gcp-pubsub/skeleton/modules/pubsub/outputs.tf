# =============================================================================
# GCP Pub/Sub Module - Outputs
# =============================================================================
# =============================================================================

output "topic_id" {
  description = "Full resource name of the topic (projects/<project>/topics/<name>)"
  value       = google_pubsub_topic.main.id
}

output "topic_name" {
  description = "Name of the topic"
  value       = google_pubsub_topic.main.name
}

output "subscription_names" {
  description = "Names of the subscriptions by short name, including dead-letter when enabled"
  value       = local.subscription_names
}

output "dead_letter_topic_name" {
  description = "Name of the dead-letter topic, or null when disabled"
  value       = one(google_pubsub_topic.dead_letter[*].name)
}

output "schema_id" {
  description = "Full resource name of the schema, or null without one"
  value       = one(google_pubsub_schema.main[*].id)
}
