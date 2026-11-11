output "cluster_id" {
  description = "ID of the cluster."
  value       = google_container_cluster.main.id
}

output "cluster_name" {
  description = "Name of the cluster."
  value       = google_container_cluster.main.name
}

output "cluster_location" {
  description = "Region of the cluster."
  value       = google_container_cluster.main.location
}

output "cluster_endpoint" {
  description = "Address of the control plane endpoint."
  value       = google_container_cluster.main.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 encoded certificate authority of the cluster."
  value       = google_container_cluster.main.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "workload_identity_pool" {
  description = "Workload Identity pool used to bind Kubernetes service accounts to IAM."
  value       = "${var.project_id}.svc.id.goog"
}

output "node_service_account_email" {
  description = "Email of the service account the nodes run as."
  value       = google_service_account.nodes.email
}

output "node_pool_names" {
  description = "Names of the workload node pools. Empty for Autopilot clusters."
  value       = [for pool in google_container_node_pool.main : pool.name]
}

output "artifact_registry_repository_id" {
  description = "ID of the Artifact Registry repository, or null when disabled."
  value       = var.enable_artifact_registry ? google_artifact_registry_repository.main[0].id : null
}

output "artifact_registry_url" {
  description = "Docker registry path to push images to, or null when disabled."
  value       = var.enable_artifact_registry ? "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main[0].repository_id}" : null
}

output "kubeconfig_command" {
  description = "gcloud command that writes cluster credentials to the local kubeconfig."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --region ${var.region} --project ${var.project_id}${var.enable_private_endpoint ? " --internal-ip" : ""}"
}
