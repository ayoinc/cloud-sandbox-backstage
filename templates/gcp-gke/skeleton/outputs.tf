output "cluster_id" {
  description = "GKE cluster ID"
  value       = var.cluster_mode == "autopilot" ? google_container_cluster.autopilot[0].id : google_container_cluster.standard[0].id
}

output "cluster_name" {
  description = "GKE cluster name"
  value       = var.cluster_mode == "autopilot" ? google_container_cluster.autopilot[0].name : google_container_cluster.standard[0].name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = var.cluster_mode == "autopilot" ? google_container_cluster.autopilot[0].endpoint : google_container_cluster.standard[0].endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = var.cluster_mode == "autopilot" ? google_container_cluster.autopilot[0].master_auth[0].cluster_ca_certificate : google_container_cluster.standard[0].master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "service_account_email" {
  description = "GKE nodes service account email"
  value       = google_service_account.gke_nodes.email
}

output "artifact_registry_url" {
  description = "Artifact Registry URL"
  value       = "${var.region}-docker.pkg.dev/${var.gcp_project}/${google_artifact_registry_repository.main.repository_id}"
}

output "get_credentials_command" {
  description = "Command to get kubectl credentials"
  value       = "gcloud container clusters get-credentials ${var.name}-${var.environment} --region ${var.region} --project ${var.gcp_project}"
}
