/**
 * Outputs for GCP Observability Module
 */

# =============================================================================
# Log Sink Outputs
# =============================================================================

output "log_sink_name" {
  description = "Name of the logging sink"
  value       = var.enable_log_sink ? google_logging_project_sink.log_sink[0].name : null
}

output "log_sink_destination" {
  description = "Destination of the logging sink (Cloud Storage bucket)"
  value       = var.enable_log_sink ? google_logging_project_sink.log_sink[0].destination : null
}

output "log_sink_writer_identity" {
  description = "The identity associated with the log sink for granting permissions"
  value       = var.enable_log_sink ? google_logging_project_sink.log_sink[0].writer_identity : null
}

output "log_bucket_name" {
  description = "Name of the Cloud Storage bucket for log sink"
  value       = var.enable_log_sink ? google_storage_bucket.log_sink_bucket[0].name : null
}

output "log_bucket_url" {
  description = "URL of the Cloud Storage bucket for log sink"
  value       = var.enable_log_sink ? google_storage_bucket.log_sink_bucket[0].url : null
}

# =============================================================================
# Notification Channel Outputs
# =============================================================================

output "notification_channel_ids" {
  description = "Map of notification channel names to their IDs"
  value = {
    email     = google_monitoring_notification_channel.email.id
    slack     = var.slack_webhook_url != null ? google_monitoring_notification_channel.slack[0].id : null
    pagerduty = var.pagerduty_service_key != null ? google_monitoring_notification_channel.pagerduty[0].id : null
  }
}

output "notification_channel_names" {
  description = "Map of notification channel types to their display names"
  value = {
    email     = google_monitoring_notification_channel.email.display_name
    slack     = var.slack_webhook_url != null ? google_monitoring_notification_channel.slack[0].display_name : null
    pagerduty = var.pagerduty_service_key != null ? google_monitoring_notification_channel.pagerduty[0].display_name : null
  }
}

output "all_notification_channel_ids" {
  description = "List of all notification channel IDs"
  value       = local.notification_channels
}

# =============================================================================
# Alert Policy Outputs
# =============================================================================

output "alert_policy_ids" {
  description = "Map of alert policy names to their IDs"
  value = {
    high_cpu            = google_monitoring_alert_policy.high_cpu.id
    high_memory         = google_monitoring_alert_policy.high_memory.id
    uptime_check_failed = var.uptime_check_host != null ? google_monitoring_alert_policy.uptime_check_failed.id : null
    error_log_entries   = google_monitoring_alert_policy.error_log_entries.id
  }
}

output "alert_policy_names" {
  description = "Map of alert policy types to their display names"
  value = {
    high_cpu            = google_monitoring_alert_policy.high_cpu.display_name
    high_memory         = google_monitoring_alert_policy.high_memory.display_name
    uptime_check_failed = var.uptime_check_host != null ? google_monitoring_alert_policy.uptime_check_failed.display_name : null
    error_log_entries   = google_monitoring_alert_policy.error_log_entries.display_name
  }
}

# =============================================================================
# Uptime Check Outputs
# =============================================================================

output "uptime_check_id" {
  description = "ID of the uptime check configuration"
  value       = var.uptime_check_host != null ? google_monitoring_uptime_check_config.https[0].uptime_check_id : null
}

output "uptime_check_name" {
  description = "Name of the uptime check configuration"
  value       = var.uptime_check_host != null ? google_monitoring_uptime_check_config.https[0].name : null
}

# =============================================================================
# Dashboard Outputs
# =============================================================================

output "dashboard_id" {
  description = "ID of the monitoring dashboard"
  value       = google_monitoring_dashboard.main.id
}

output "dashboard_name" {
  description = "Name of the monitoring dashboard"
  value       = var.dashboard_display_name
}

# =============================================================================
# Log Metric Outputs
# =============================================================================

output "log_metric_names" {
  description = "Map of log-based metric types to their names"
  value = {
    error_count       = google_logging_metric.error_count.name
    request_latency   = google_logging_metric.latency.name
    http_status_codes = google_logging_metric.http_status_codes.name
  }
}

output "log_metric_ids" {
  description = "Map of log-based metric types to their IDs"
  value = {
    error_count       = google_logging_metric.error_count.id
    request_latency   = google_logging_metric.latency.id
    http_status_codes = google_logging_metric.http_status_codes.id
  }
}

# =============================================================================
# Summary Output
# =============================================================================

output "observability_summary" {
  description = "Summary of all observability resources created"
  value = {
    project_id   = var.project_id
    environment  = var.environment
    region       = var.region
    log_sink     = var.enable_log_sink ? "enabled" : "disabled"
    uptime_check = var.uptime_check_host != null ? var.uptime_check_host : "disabled"
    alerts       = var.enable_alerts ? "enabled" : "disabled"
    notification_channels = compact([
      "email",
      var.slack_webhook_url != null ? "slack" : "",
      var.pagerduty_service_key != null ? "pagerduty" : ""
    ])
  }
}
