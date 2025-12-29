output "service_id" {
  description = "The unique identifier of the Cloud Run service"
  value       = google_cloud_run_v2_service.this.id
}

output "service_name" {
  description = "The name of the Cloud Run service"
  value       = google_cloud_run_v2_service.this.name
}

output "service_uri" {
  description = "The URI of the Cloud Run service"
  value       = google_cloud_run_v2_service.this.uri
}

output "latest_ready_revision" {
  description = "The latest ready revision of the Cloud Run service"
  value       = google_cloud_run_v2_service.this.latest_ready_revision
}
