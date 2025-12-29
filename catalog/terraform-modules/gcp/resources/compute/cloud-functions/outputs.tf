output "function_id" {
  description = "The unique identifier of the Cloud Function"
  value       = google_cloudfunctions2_function.function.id
}

output "function_name" {
  description = "The name of the Cloud Function"
  value       = google_cloudfunctions2_function.function.name
}

output "function_uri" {
  description = "The URI of the Cloud Function (HTTPS endpoint for HTTP triggers)"
  value       = google_cloudfunctions2_function.function.service_config[0].uri
}

output "service_account_email" {
  description = "The service account email used by the Cloud Function"
  value       = google_cloudfunctions2_function.function.service_config[0].service_account_email
}
