# -----------------------------------------------------------------------------
# GCP Kubernetes (GKE) Module - Outputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Cluster Outputs
# -----------------------------------------------------------------------------

output "cluster_id" {
  description = "The unique identifier of the GKE cluster"
  value       = google_container_cluster.main.id
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.main.name
}

output "cluster_endpoint" {
  description = "The IP address of the Kubernetes master endpoint"
  value       = google_container_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64 encoded public certificate for the cluster's CA"
  value       = google_container_cluster.main.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "The location (region) of the GKE cluster"
  value       = google_container_cluster.main.location
}

output "cluster_self_link" {
  description = "The server-defined URL for the resource"
  value       = google_container_cluster.main.self_link
}

output "cluster_master_version" {
  description = "The current version of the master in the cluster"
  value       = google_container_cluster.main.master_version
}

# -----------------------------------------------------------------------------
# Node Pool Outputs
# -----------------------------------------------------------------------------

output "node_pools" {
  description = "Map of node pool names to their configuration"
  value = {
    for name, pool in google_container_node_pool.pools : name => {
      id                  = pool.id
      name                = pool.name
      instance_group_urls = pool.instance_group_urls
      node_count          = pool.node_count
      version             = pool.version
    }
  }
}

output "node_pool_names" {
  description = "List of node pool names"
  value       = [for pool in google_container_node_pool.pools : pool.name]
}

# -----------------------------------------------------------------------------
# Network Outputs
# -----------------------------------------------------------------------------

output "cluster_ipv4_cidr" {
  description = "The IP range of the Kubernetes pods in the cluster"
  value       = google_container_cluster.main.cluster_ipv4_cidr
}

output "services_ipv4_cidr" {
  description = "The IP range of the Kubernetes services in the cluster"
  value       = google_container_cluster.main.services_ipv4_cidr
}

output "private_endpoint" {
  description = "The private IP address of the master (when private cluster is enabled)"
  value       = var.enable_private_cluster ? google_container_cluster.main.private_cluster_config[0].private_endpoint : null
}

output "public_endpoint" {
  description = "The public IP address of the master (when not using private endpoint)"
  value       = var.enable_private_cluster && var.enable_private_endpoint ? null : google_container_cluster.main.endpoint
}

output "peering_name" {
  description = "The name of the peering connection between the GKE VPC and the master VPC"
  value       = var.enable_private_cluster ? google_container_cluster.main.private_cluster_config[0].peering_name : null
}

# -----------------------------------------------------------------------------
# Identity Outputs
# -----------------------------------------------------------------------------

output "workload_identity_pool" {
  description = "The Workload Identity pool for the cluster"
  value       = local.workload_identity_pool
}

output "node_service_account_email" {
  description = "Email address of the service account used by GKE nodes"
  value       = google_service_account.gke_nodes.email
}

output "node_service_account_id" {
  description = "Unique ID of the service account used by GKE nodes"
  value       = google_service_account.gke_nodes.unique_id
}

# -----------------------------------------------------------------------------
# Container Registry Outputs
# -----------------------------------------------------------------------------

output "container_registry_bucket" {
  description = "The GCS bucket for Container Registry (if enabled)"
  value       = var.enable_container_registry ? google_container_registry.main[0].id : null
}

# -----------------------------------------------------------------------------
# Artifact Registry Outputs
# -----------------------------------------------------------------------------

output "artifact_registry_id" {
  description = "The ID of the Artifact Registry repository"
  value       = var.enable_artifact_registry ? google_artifact_registry_repository.main[0].id : null
}

output "artifact_registry_name" {
  description = "The name of the Artifact Registry repository"
  value       = var.enable_artifact_registry ? google_artifact_registry_repository.main[0].name : null
}

output "artifact_registry_location" {
  description = "The location of the Artifact Registry repository"
  value       = var.enable_artifact_registry ? google_artifact_registry_repository.main[0].location : null
}

output "artifact_registry_url" {
  description = "The URL of the Artifact Registry repository for Docker push/pull"
  value       = var.enable_artifact_registry ? "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main[0].name}" : null
}

# -----------------------------------------------------------------------------
# Kubeconfig Command
# -----------------------------------------------------------------------------

output "kubeconfig_command" {
  description = "Command to configure kubectl to connect to the cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --region ${google_container_cluster.main.location} --project ${var.project_id}"
}

output "kubeconfig_command_internal" {
  description = "Command to configure kubectl to connect to the cluster via internal endpoint"
  value       = var.enable_private_cluster ? "gcloud container clusters get-credentials ${google_container_cluster.main.name} --region ${google_container_cluster.main.location} --project ${var.project_id} --internal-ip" : null
}

# -----------------------------------------------------------------------------
# Additional Cluster Info
# -----------------------------------------------------------------------------

output "cluster_labels" {
  description = "Labels applied to the cluster"
  value       = google_container_cluster.main.resource_labels
}

output "release_channel" {
  description = "The release channel of the cluster"
  value       = google_container_cluster.main.release_channel[0].channel
}

output "logging_service" {
  description = "The logging service used by the cluster"
  value       = google_container_cluster.main.logging_service
}

output "monitoring_service" {
  description = "The monitoring service used by the cluster"
  value       = google_container_cluster.main.monitoring_service
}

output "network_policy_enabled" {
  description = "Whether network policy is enabled"
  value       = google_container_cluster.main.network_policy[0].enabled
}

output "datapath_provider" {
  description = "The datapath provider for the cluster"
  value       = google_container_cluster.main.datapath_provider
}
