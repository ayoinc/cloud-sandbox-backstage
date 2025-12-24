# =============================================================================
# GCP GKE Module - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Cluster Outputs
# -----------------------------------------------------------------------------

output "cluster_id" {
  description = "GKE cluster ID"
  value = var.cluster_mode == "autopilot" ? (
    google_container_cluster.autopilot[0].id
  ) : google_container_cluster.standard[0].id
}

output "cluster_name" {
  description = "GKE cluster name"
  value = var.cluster_mode == "autopilot" ? (
    google_container_cluster.autopilot[0].name
  ) : google_container_cluster.standard[0].name
}

output "cluster_self_link" {
  description = "GKE cluster self link"
  value = var.cluster_mode == "autopilot" ? (
    google_container_cluster.autopilot[0].self_link
  ) : google_container_cluster.standard[0].self_link
}

output "cluster_endpoint" {
  description = "GKE cluster API endpoint"
  value = var.cluster_mode == "autopilot" ? (
    google_container_cluster.autopilot[0].endpoint
  ) : google_container_cluster.standard[0].endpoint
  sensitive = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate (base64 encoded)"
  value = var.cluster_mode == "autopilot" ? (
    google_container_cluster.autopilot[0].master_auth[0].cluster_ca_certificate
  ) : google_container_cluster.standard[0].master_auth[0].cluster_ca_certificate
  sensitive = true
}

output "cluster_location" {
  description = "GKE cluster location (region)"
  value       = var.region
}

output "cluster_mode" {
  description = "GKE cluster mode (autopilot or standard)"
  value       = var.cluster_mode
}

# -----------------------------------------------------------------------------
# Service Account Outputs
# -----------------------------------------------------------------------------

output "service_account_email" {
  description = "GKE nodes service account email"
  value       = google_service_account.gke_nodes.email
}

output "service_account_name" {
  description = "GKE nodes service account name"
  value       = google_service_account.gke_nodes.name
}

# -----------------------------------------------------------------------------
# Artifact Registry Outputs
# -----------------------------------------------------------------------------

output "artifact_registry_id" {
  description = "Artifact Registry repository ID (null if not created)"
  value       = var.create_artifact_registry ? google_artifact_registry_repository.main[0].id : null
}

output "artifact_registry_name" {
  description = "Artifact Registry repository name (null if not created)"
  value       = var.create_artifact_registry ? google_artifact_registry_repository.main[0].repository_id : null
}

output "artifact_registry_url" {
  description = "Artifact Registry URL for docker push/pull"
  value = var.create_artifact_registry ? (
    "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main[0].repository_id}"
  ) : null
}

# -----------------------------------------------------------------------------
# Node Pool Outputs (Standard Mode Only)
# -----------------------------------------------------------------------------

output "primary_node_pool_name" {
  description = "Primary node pool name (null for Autopilot mode)"
  value       = var.cluster_mode == "standard" ? google_container_node_pool.primary[0].name : null
}

output "additional_node_pool_names" {
  description = "List of additional node pool names"
  value = var.cluster_mode == "standard" ? [
    for name, pool in google_container_node_pool.additional : name
  ] : []
}

# -----------------------------------------------------------------------------
# Kubectl Connection Commands
# -----------------------------------------------------------------------------

output "get_credentials_command" {
  description = "gcloud command to get kubectl credentials"
  value = join(" ", [
    "gcloud container clusters get-credentials",
    var.cluster_mode == "autopilot" ? google_container_cluster.autopilot[0].name : google_container_cluster.standard[0].name,
    "--region", var.region,
    "--project", var.project_id
  ])
}

# -----------------------------------------------------------------------------
# Workload Identity Outputs
# -----------------------------------------------------------------------------

output "workload_identity_pool" {
  description = "Workload Identity pool for the cluster"
  value       = "${var.project_id}.svc.id.goog"
}

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------

output "gke_info" {
  description = "Summary of GKE cluster configuration"
  value = {
    name     = var.cluster_mode == "autopilot" ? google_container_cluster.autopilot[0].name : google_container_cluster.standard[0].name
    id       = var.cluster_mode == "autopilot" ? google_container_cluster.autopilot[0].id : google_container_cluster.standard[0].id
    location = var.region
    mode     = var.cluster_mode

    network = {
      vpc_id    = var.network_id
      subnet_id = var.subnet_id
    }

    service_account = google_service_account.gke_nodes.email

    artifact_registry = var.create_artifact_registry ? {
      name = google_artifact_registry_repository.main[0].repository_id
      url  = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main[0].repository_id}"
    } : null

    node_pools = var.cluster_mode == "standard" ? {
      primary    = google_container_node_pool.primary[0].name
      additional = [for name, pool in google_container_node_pool.additional : name]
    } : null

    private_endpoint = var.enable_private_endpoint
    release_channel  = var.release_channel
  }
}
