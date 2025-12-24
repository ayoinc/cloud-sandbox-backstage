# =============================================================================
# GCP Cloud Run Module - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Service Outputs
# -----------------------------------------------------------------------------

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

output "service_location" {
  description = "Cloud Run service location"
  value       = google_cloud_run_v2_service.main.location
}

output "latest_revision" {
  description = "Latest ready revision name"
  value       = google_cloud_run_v2_service.main.latest_ready_revision
}

output "latest_created_revision" {
  description = "Latest created revision name"
  value       = google_cloud_run_v2_service.main.latest_created_revision
}

# -----------------------------------------------------------------------------
# Service Account Outputs
# -----------------------------------------------------------------------------

output "service_account_email" {
  description = "Cloud Run service account email"
  value       = google_service_account.cloud_run.email
}

output "service_account_name" {
  description = "Cloud Run service account name"
  value       = google_service_account.cloud_run.name
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
# VPC Connector Outputs
# -----------------------------------------------------------------------------

output "vpc_connector_id" {
  description = "VPC Access Connector ID (null if not created)"
  value       = var.create_vpc_connector ? google_vpc_access_connector.main[0].id : null
}

output "vpc_connector_name" {
  description = "VPC Access Connector name (null if not created)"
  value       = var.create_vpc_connector ? google_vpc_access_connector.main[0].name : null
}

# -----------------------------------------------------------------------------
# Monitoring Outputs
# -----------------------------------------------------------------------------

output "latency_alert_id" {
  description = "High latency alert policy ID (null if monitoring disabled)"
  value       = var.enable_monitoring_alerts ? google_monitoring_alert_policy.high_latency[0].id : null
}

output "error_rate_alert_id" {
  description = "High error rate alert policy ID (null if monitoring disabled)"
  value       = var.enable_monitoring_alerts ? google_monitoring_alert_policy.high_error_rate[0].id : null
}

# -----------------------------------------------------------------------------
# Docker Commands
# -----------------------------------------------------------------------------

output "docker_push_command" {
  description = "Docker command to push images to Artifact Registry"
  value = var.create_artifact_registry ? (
    "docker push ${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main[0].repository_id}/${var.name}:TAG"
  ) : null
}

output "gcloud_deploy_command" {
  description = "gcloud command to deploy a new revision"
  value = join(" ", [
    "gcloud run deploy", google_cloud_run_v2_service.main.name,
    "--image", var.create_artifact_registry ? "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main[0].repository_id}/${var.name}:TAG" : "IMAGE_URL",
    "--region", var.region,
    "--project", var.project_id
  ])
}

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------

output "cloud_run_info" {
  description = "Summary of Cloud Run service configuration"
  value = {
    name     = google_cloud_run_v2_service.main.name
    id       = google_cloud_run_v2_service.main.id
    url      = google_cloud_run_v2_service.main.uri
    location = google_cloud_run_v2_service.main.location

    scaling = {
      min_instances = var.min_instances
      max_instances = var.max_instances
    }

    resources = {
      cpu    = var.cpu
      memory = var.memory
    }

    service_account = google_service_account.cloud_run.email

    artifact_registry = var.create_artifact_registry ? {
      name = google_artifact_registry_repository.main[0].repository_id
      url  = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main[0].repository_id}"
    } : null

    vpc_connector = var.create_vpc_connector ? {
      name = google_vpc_access_connector.main[0].name
    } : null

    ingress               = var.ingress
    allow_unauthenticated = var.allow_unauthenticated
    monitoring_enabled    = var.enable_monitoring_alerts
  }
}
