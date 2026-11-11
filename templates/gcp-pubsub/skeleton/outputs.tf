# =============================================================================
# GCP Pub/Sub - Root Outputs
# =============================================================================
# =============================================================================

output "topic_id" {
  description = "Full resource name of the topic (projects/<project>/topics/<name>)"
  value       = module.pubsub.topic_id
}

output "topic_name" {
  description = "Name of the topic"
  value       = module.pubsub.topic_name
}

output "subscription_names" {
  description = "Names of the subscriptions by short name, including dead-letter when enabled"
  value       = module.pubsub.subscription_names
}

output "dead_letter_topic_name" {
  description = "Name of the dead-letter topic, or null when disabled"
  value       = module.pubsub.dead_letter_topic_name
}

output "schema_id" {
  description = "Full resource name of the schema, or null without one"
  value       = module.pubsub.schema_id
}
