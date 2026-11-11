output "log_bucket_name" {
  description = "Name of the log archive bucket, or null when the sink is disabled."
  value       = var.enable_log_sink ? google_storage_bucket.logs[0].name : null
}

output "log_sink_name" {
  description = "Name of the log sink, or null when disabled."
  value       = var.enable_log_sink ? google_logging_project_sink.archive[0].name : null
}

output "log_sink_writer_identity" {
  description = "Service account the sink writes with, or null when disabled."
  value       = var.enable_log_sink ? google_logging_project_sink.archive[0].writer_identity : null
}

output "error_metric_name" {
  description = "Name of the log-based metric counting error entries."
  value       = google_logging_metric.error_count.name
}

output "notification_channel_ids" {
  description = "IDs of the notification channels attached to every alert policy."
  value       = local.notification_channel_ids
}

output "alert_policy_ids" {
  description = "IDs of the alert policies keyed by purpose."
  value = merge(
    { for policy in google_monitoring_alert_policy.high_cpu : "high_cpu" => policy.id },
    { for policy in google_monitoring_alert_policy.high_memory : "high_memory" => policy.id },
    { for policy in google_monitoring_alert_policy.error_logs : "error_logs" => policy.id },
    { for policy in google_monitoring_alert_policy.uptime : "uptime" => policy.id },
  )
}

output "uptime_check_id" {
  description = "ID of the uptime check, or null when no host is configured."
  value       = var.uptime_check_host == null ? null : google_monitoring_uptime_check_config.https[0].uptime_check_id
}

output "dashboard_id" {
  description = "ID of the dashboard, or null when disabled."
  value       = var.enable_dashboard ? google_monitoring_dashboard.main[0].id : null
}
