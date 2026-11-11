# =============================================================================
# GCP Cloud Run Functions - Root Outputs
# =============================================================================
# =============================================================================

output "function_name" {
  description = "Name of the function"
  value       = module.cloud_function.function_name
}

output "function_uri" {
  description = "HTTPS URL of the function"
  value       = module.cloud_function.function_uri
}

output "runtime_service_account_email" {
  description = "Service account the function runs as; grant it the roles the code needs"
  value       = module.cloud_function.runtime_service_account_email
}

output "build_service_account_email" {
  description = "Service account that builds the function"
  value       = module.cloud_function.build_service_account_email
}

output "source_bucket_name" {
  description = "Bucket holding the zipped source"
  value       = module.cloud_function.source_bucket_name
}

output "trigger_topic_name" {
  description = "Pub/Sub topic that triggers the function, or null for an HTTP function"
  value       = module.cloud_function.trigger_topic_name
}
