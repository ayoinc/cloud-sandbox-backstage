output "linked_account_id" {
  description = "ID of the linked Google Cloud project in New Relic."
  value       = newrelic_cloud_gcp_link_account.this.id
}

output "service_account_email" {
  description = "Email of the service account New Relic impersonates."
  value       = google_service_account.newrelic.email
}

output "workload_identity_provider" {
  description = "Resource name of the workload identity pool provider that trusts New Relic."
  value       = google_iam_workload_identity_pool_provider.newrelic.name
}
