# =============================================================================
# GCP GKE - Root Outputs
# =============================================================================
# Exposes outputs from the GKE module
# =============================================================================

# -----------------------------------------------------------------------------
# Cluster Outputs
# -----------------------------------------------------------------------------

output "cluster_id" {
  description = "GKE cluster ID"
  value       = module.gke.cluster_id
}

output "cluster_name" {
  description = "GKE cluster name"
  value       = module.gke.cluster_name
}

output "cluster_self_link" {
  description = "GKE cluster self link"
  value       = module.gke.cluster_self_link
}

output "cluster_endpoint" {
  description = "GKE cluster API endpoint"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate (base64 encoded)"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "GKE cluster location (region)"
  value       = module.gke.cluster_location
}

output "cluster_mode" {
  description = "GKE cluster mode (autopilot or standard)"
  value       = module.gke.cluster_mode
}

# -----------------------------------------------------------------------------
# Service Account Outputs
# -----------------------------------------------------------------------------

output "service_account_email" {
  description = "GKE nodes service account email"
  value       = module.gke.service_account_email
}

output "service_account_name" {
  description = "GKE nodes service account name"
  value       = module.gke.service_account_name
}

# -----------------------------------------------------------------------------
# Artifact Registry Outputs
# -----------------------------------------------------------------------------

output "artifact_registry_id" {
  description = "Artifact Registry repository ID (null if not created)"
  value       = module.gke.artifact_registry_id
}

output "artifact_registry_name" {
  description = "Artifact Registry repository name (null if not created)"
  value       = module.gke.artifact_registry_name
}

output "artifact_registry_url" {
  description = "Artifact Registry URL for docker push/pull"
  value       = module.gke.artifact_registry_url
}

# -----------------------------------------------------------------------------
# Node Pool Outputs
# -----------------------------------------------------------------------------

output "primary_node_pool_name" {
  description = "Primary node pool name (null for Autopilot mode)"
  value       = module.gke.primary_node_pool_name
}

output "additional_node_pool_names" {
  description = "List of additional node pool names"
  value       = module.gke.additional_node_pool_names
}

# -----------------------------------------------------------------------------
# Connection Commands
# -----------------------------------------------------------------------------

output "get_credentials_command" {
  description = "gcloud command to get kubectl credentials"
  value       = module.gke.get_credentials_command
}

# -----------------------------------------------------------------------------
# Workload Identity
# -----------------------------------------------------------------------------

output "workload_identity_pool" {
  description = "Workload Identity pool for the cluster"
  value       = module.gke.workload_identity_pool
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

output "gke_info" {
  description = "Summary of GKE cluster configuration"
  value       = module.gke.gke_info
}
