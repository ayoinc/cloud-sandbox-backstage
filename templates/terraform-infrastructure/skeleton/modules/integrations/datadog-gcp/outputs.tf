output "integration_id" {
  description = "ID of the Google Cloud integration in Datadog."
  value       = datadog_integration_gcp_sts.this.id
}

output "service_account_email" {
  description = "Email of the service account Datadog impersonates."
  value       = google_service_account.datadog.email
}

output "delegate_account_email" {
  description = "Datadog principal that is allowed to impersonate the service account."
  value       = datadog_integration_gcp_sts.this.delegate_account_email
}
