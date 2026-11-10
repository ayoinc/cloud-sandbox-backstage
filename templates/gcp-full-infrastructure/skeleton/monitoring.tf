# =============================================================================
# Monitoring: error metric, alert policy and notification channel
# =============================================================================

resource "google_logging_metric" "errors" {
  count = var.enable_monitoring ? 1 : 0

  name        = "${local.name_prefix}-errors"
  description = "Log entries with severity ERROR or higher"
  filter      = "severity>=ERROR"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }

  depends_on = [google_project_service.main]
}

resource "google_monitoring_notification_channel" "email" {
  count = var.enable_monitoring && var.alert_email != "" ? 1 : 0

  display_name = "${local.name_prefix} alerts"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }

  depends_on = [google_project_service.main]
}

resource "google_monitoring_alert_policy" "errors" {
  count = var.enable_monitoring ? 1 : 0

  display_name          = "${local.name_prefix} error log rate"
  combiner              = "OR"
  notification_channels = google_monitoring_notification_channel.email[*].id
  user_labels           = local.labels

  conditions {
    display_name = "Error log entries per minute"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.errors[0].name}\" AND resource.type=\"global\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.error_log_threshold
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }
}
