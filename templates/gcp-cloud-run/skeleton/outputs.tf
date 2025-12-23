output "service_id" {
  description = "Cloud Run service ID"
  value       = google_cloud_run_v2_service.main.id
}

output "service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.main.name
}

output "service_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.main.uri
}

output "service_account_email" {
  description = "Service account email"
  value       = google_service_account.cloudrun.email
}

output "artifact_registry_url" {
  description = "Artifact Registry URL for pushing images"
  value       = "${var.region}-docker.pkg.dev/${var.gcp_project}/${google_artifact_registry_repository.main.repository_id}"
}

output "latest_revision" {
  description = "Latest revision name"
  value       = google_cloud_run_v2_service.main.latest_ready_revision
}
