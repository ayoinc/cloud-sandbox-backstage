output "deploy_type" {
  description = "Deployed service type: run or function."
  value       = var.deploy_type
}

output "service_name" {
  description = "Name of the Cloud Run service or Cloud Function."
  value       = local.service_name
}

output "service_url" {
  description = "HTTPS URL of the service."
  value       = local.service_uri
}

output "service_id" {
  description = "ID of the Cloud Run service or Cloud Function."
  value       = local.is_function ? google_cloudfunctions2_function.main[0].id : google_cloud_run_v2_service.main[0].id
}

output "service_account_email" {
  description = "Email of the runtime service account."
  value       = google_service_account.runtime.email
}

output "invoker_service_account_email" {
  description = "Email of the service account Pub/Sub and Cloud Scheduler call the service with, or null when neither is enabled."
  value       = local.create_invoker ? google_service_account.invoker[0].email : null
}

output "source_bucket_name" {
  description = "Name of the bucket holding the function source, or null for Cloud Run."
  value       = local.is_function ? google_storage_bucket.function_source[0].name : null
}

output "pubsub_topic_id" {
  description = "ID of the Pub/Sub topic, or null when disabled."
  value       = var.enable_pubsub ? google_pubsub_topic.main[0].id : null
}

output "pubsub_topic_name" {
  description = "Name of the Pub/Sub topic, or null when disabled."
  value       = var.enable_pubsub ? google_pubsub_topic.main[0].name : null
}

output "pubsub_subscription_name" {
  description = "Name of the push subscription, or null when disabled."
  value       = var.enable_pubsub ? google_pubsub_subscription.push[0].name : null
}

output "scheduler_job_name" {
  description = "Name of the Cloud Scheduler job, or null when no schedule is set."
  value       = var.schedule_cron == null ? null : google_cloud_scheduler_job.main[0].name
}
