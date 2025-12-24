# =============================================================================
# GCP Cloud Run - Root Outputs
# =============================================================================
# Exposes outputs from the Cloud Run module
# =============================================================================

# -----------------------------------------------------------------------------
# Service Outputs
# -----------------------------------------------------------------------------

output "service_id" {
  description = "Cloud Run service ID"
  value       = module.cloud_run.service_id
}

output "service_name" {
  description = "Cloud Run service name"
  value       = module.cloud_run.service_name
}

output "service_url" {
  description = "Cloud Run service URL"
  value       = module.cloud_run.service_url
}

output "service_location" {
  description = "Cloud Run service location"
  value       = module.cloud_run.service_location
}

output "latest_revision" {
  description = "Latest ready revision name"
  value       = module.cloud_run.latest_revision
}

# -----------------------------------------------------------------------------
# Service Account Outputs
# -----------------------------------------------------------------------------

output "service_account_email" {
  description = "Cloud Run service account email"
  value       = module.cloud_run.service_account_email
}

output "service_account_name" {
  description = "Cloud Run service account name"
  value       = module.cloud_run.service_account_name
}

# -----------------------------------------------------------------------------
# Artifact Registry Outputs
# -----------------------------------------------------------------------------

output "artifact_registry_id" {
  description = "Artifact Registry repository ID (null if not created)"
  value       = module.cloud_run.artifact_registry_id
}

output "artifact_registry_name" {
  description = "Artifact Registry repository name (null if not created)"
  value       = module.cloud_run.artifact_registry_name
}

output "artifact_registry_url" {
  description = "Artifact Registry URL for docker push/pull"
  value       = module.cloud_run.artifact_registry_url
}

# -----------------------------------------------------------------------------
# VPC Connector Outputs
# -----------------------------------------------------------------------------

output "vpc_connector_id" {
  description = "VPC Access Connector ID (null if not created)"
  value       = module.cloud_run.vpc_connector_id
}

output "vpc_connector_name" {
  description = "VPC Access Connector name (null if not created)"
  value       = module.cloud_run.vpc_connector_name
}

# -----------------------------------------------------------------------------
# Deployment Commands
# -----------------------------------------------------------------------------

output "docker_push_command" {
  description = "Docker command to push images to Artifact Registry"
  value       = module.cloud_run.docker_push_command
}

output "gcloud_deploy_command" {
  description = "gcloud command to deploy a new revision"
  value       = module.cloud_run.gcloud_deploy_command
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

output "cloud_run_info" {
  description = "Summary of Cloud Run service configuration"
  value       = module.cloud_run.cloud_run_info
}
