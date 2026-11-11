# =============================================================================
# GCP Cloud Run Functions Module - Outputs
# =============================================================================
# =============================================================================

output "function_name" {
  description = "Name of the function"
  value       = google_cloudfunctions2_function.main.name
}

output "function_uri" {
  description = "HTTPS URL of the function"
  value       = google_cloudfunctions2_function.main.service_config[0].uri
}

output "runtime_service_account_email" {
  description = "Service account the function runs as; grant it the roles the code needs"
  value       = google_service_account.runtime.email
}

output "build_service_account_email" {
  description = "Service account that builds the function"
  value       = google_service_account.build.email
}

output "source_bucket_name" {
  description = "Bucket holding the zipped source"
  value       = google_storage_bucket.source.name
}

output "trigger_topic_name" {
  description = "Pub/Sub topic that triggers the function, or null for an HTTP function"
  value       = one(google_pubsub_topic.trigger[*].name)
}
