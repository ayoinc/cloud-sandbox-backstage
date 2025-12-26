# -----------------------------------------------------------------------------
# GCP Serverless Module - Outputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Cloud Functions Outputs
# -----------------------------------------------------------------------------

output "function_id" {
  description = "ID of the Cloud Function (if deployed)"
  value       = var.deploy_type == "function" ? google_cloudfunctions2_function.main[0].id : null
}

output "function_name" {
  description = "Name of the Cloud Function (if deployed)"
  value       = var.deploy_type == "function" ? google_cloudfunctions2_function.main[0].name : null
}

output "function_uri" {
  description = "URI of the Cloud Function (if deployed)"
  value       = var.deploy_type == "function" ? google_cloudfunctions2_function.main[0].service_config[0].uri : null
}

output "function_url" {
  description = "HTTPS URL of the Cloud Function (if deployed)"
  value       = var.deploy_type == "function" ? google_cloudfunctions2_function.main[0].url : null
}

output "function_state" {
  description = "State of the Cloud Function (if deployed)"
  value       = var.deploy_type == "function" ? google_cloudfunctions2_function.main[0].state : null
}

output "function_update_time" {
  description = "Last update time of the Cloud Function (if deployed)"
  value       = var.deploy_type == "function" ? google_cloudfunctions2_function.main[0].update_time : null
}

# -----------------------------------------------------------------------------
# Cloud Run Outputs
# -----------------------------------------------------------------------------

output "cloud_run_id" {
  description = "ID of the Cloud Run service (if deployed)"
  value       = var.deploy_type == "run" ? google_cloud_run_v2_service.main[0].id : null
}

output "cloud_run_name" {
  description = "Name of the Cloud Run service (if deployed)"
  value       = var.deploy_type == "run" ? google_cloud_run_v2_service.main[0].name : null
}

output "cloud_run_uri" {
  description = "URI of the Cloud Run service (if deployed)"
  value       = var.deploy_type == "run" ? google_cloud_run_v2_service.main[0].uri : null
}

output "cloud_run_generation" {
  description = "Generation of the Cloud Run service (if deployed)"
  value       = var.deploy_type == "run" ? google_cloud_run_v2_service.main[0].generation : null
}

output "cloud_run_latest_revision" {
  description = "Latest ready revision of the Cloud Run service (if deployed)"
  value       = var.deploy_type == "run" ? google_cloud_run_v2_service.main[0].latest_ready_revision : null
}

# -----------------------------------------------------------------------------
# Unified Service Outputs
# -----------------------------------------------------------------------------

output "service_url" {
  description = "URL of the deployed service (function or Cloud Run)"
  value = var.deploy_type == "function" ? (
    google_cloudfunctions2_function.main[0].url
    ) : (
    google_cloud_run_v2_service.main[0].uri
  )
}

output "service_name" {
  description = "Name of the deployed service"
  value = var.deploy_type == "function" ? (
    google_cloudfunctions2_function.main[0].name
    ) : (
    google_cloud_run_v2_service.main[0].name
  )
}

# -----------------------------------------------------------------------------
# Service Account Outputs
# -----------------------------------------------------------------------------

output "service_account_email" {
  description = "Email of the serverless service account"
  value       = google_service_account.serverless.email
}

output "service_account_id" {
  description = "ID of the serverless service account"
  value       = google_service_account.serverless.id
}

output "service_account_unique_id" {
  description = "Unique ID of the serverless service account"
  value       = google_service_account.serverless.unique_id
}

output "service_account_name" {
  description = "Name of the serverless service account"
  value       = google_service_account.serverless.name
}

# -----------------------------------------------------------------------------
# Storage Outputs
# -----------------------------------------------------------------------------

output "source_bucket_name" {
  description = "Name of the source storage bucket"
  value       = google_storage_bucket.function_source.name
}

output "source_bucket_url" {
  description = "URL of the source storage bucket"
  value       = google_storage_bucket.function_source.url
}

output "source_object_name" {
  description = "Name of the source object in the bucket"
  value       = google_storage_bucket_object.function_source.name
}

# -----------------------------------------------------------------------------
# API Gateway Outputs
# -----------------------------------------------------------------------------

output "api_gateway_id" {
  description = "ID of the API Gateway (if enabled)"
  value       = var.enable_api_gateway ? google_api_gateway_gateway.main[0].id : null
}

output "api_gateway_name" {
  description = "Name of the API Gateway (if enabled)"
  value       = var.enable_api_gateway ? google_api_gateway_gateway.main[0].name : null
}

output "api_gateway_url" {
  description = "Default hostname of the API Gateway (if enabled)"
  value       = var.enable_api_gateway ? google_api_gateway_gateway.main[0].default_hostname : null
}

output "api_gateway_api_id" {
  description = "ID of the API Gateway API (if enabled)"
  value       = var.enable_api_gateway ? google_api_gateway_api.main[0].api_id : null
}

output "api_gateway_config_id" {
  description = "ID of the API Gateway config (if enabled)"
  value       = var.enable_api_gateway ? google_api_gateway_api_config.main[0].api_config_id : null
}

# -----------------------------------------------------------------------------
# Pub/Sub Outputs
# -----------------------------------------------------------------------------

output "pubsub_topic_id" {
  description = "ID of the Pub/Sub topic (if enabled)"
  value       = var.enable_pubsub ? google_pubsub_topic.main[0].id : null
}

output "pubsub_topic_name" {
  description = "Name of the Pub/Sub topic (if enabled)"
  value       = var.enable_pubsub ? google_pubsub_topic.main[0].name : null
}

output "pubsub_subscription_id" {
  description = "ID of the Pub/Sub subscription (if enabled)"
  value       = var.enable_pubsub ? google_pubsub_subscription.main[0].id : null
}

output "pubsub_subscription_name" {
  description = "Name of the Pub/Sub subscription (if enabled)"
  value       = var.enable_pubsub ? google_pubsub_subscription.main[0].name : null
}

# -----------------------------------------------------------------------------
# Cloud Scheduler Outputs
# -----------------------------------------------------------------------------

output "scheduler_job_id" {
  description = "ID of the Cloud Scheduler job (if enabled)"
  value       = var.schedule_cron != "" ? google_cloud_scheduler_job.main[0].id : null
}

output "scheduler_job_name" {
  description = "Name of the Cloud Scheduler job (if enabled)"
  value       = var.schedule_cron != "" ? google_cloud_scheduler_job.main[0].name : null
}

output "scheduler_job_state" {
  description = "State of the Cloud Scheduler job (if enabled)"
  value       = var.schedule_cron != "" ? google_cloud_scheduler_job.main[0].state : null
}

# -----------------------------------------------------------------------------
# Computed Outputs
# -----------------------------------------------------------------------------

output "deploy_type" {
  description = "Deployment type used (function or run)"
  value       = var.deploy_type
}

output "region" {
  description = "Region where resources are deployed"
  value       = var.region
}

output "project_id" {
  description = "Project ID where resources are deployed"
  value       = var.project_id
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
