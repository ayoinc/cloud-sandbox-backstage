/**
 * GCP Observability Module
 *
 * This module provisions comprehensive observability infrastructure including:
 * - Log sinks and storage
 * - Monitoring notification channels
 * - Alert policies
 * - Uptime checks
 * - Custom dashboards
 * - Log-based metrics
 */

locals {
  resource_prefix = "${var.project_id}-${var.environment}"
  common_labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
    module      = "observability"
  })
}

# =============================================================================
# Log Sink and Storage
# =============================================================================

resource "google_storage_bucket" "log_sink_bucket" {
  count = var.enable_log_sink ? 1 : 0

  name          = "${local.resource_prefix}-log-sink-${random_id.bucket_suffix[0].hex}"
  project       = var.project_id
  location      = var.region
  storage_class = var.log_sink_storage_class
  force_destroy = var.force_destroy_log_bucket

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = var.log_retention_days
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = var.log_archive_days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  labels = local.common_labels
}

resource "random_id" "bucket_suffix" {
  count       = var.enable_log_sink ? 1 : 0
  byte_length = 4
}

resource "google_logging_project_sink" "log_sink" {
  count = var.enable_log_sink ? 1 : 0

  name        = "${local.resource_prefix}-log-sink"
  project     = var.project_id
  destination = "storage.googleapis.com/${google_storage_bucket.log_sink_bucket[0].name}"
  filter      = var.log_filter

  unique_writer_identity = true

  exclusions {
    name        = "exclude-debug-logs"
    description = "Exclude debug level logs to reduce storage costs"
    filter      = "severity = DEBUG"
    disabled    = false
  }
}

resource "google_storage_bucket_iam_member" "log_sink_writer" {
  count = var.enable_log_sink ? 1 : 0

  bucket = google_storage_bucket.log_sink_bucket[0].name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.log_sink[0].writer_identity
}

# =============================================================================
# Notification Channels
# =============================================================================

resource "google_monitoring_notification_channel" "email" {
  display_name = "${var.environment} Email Notification"
  project      = var.project_id
  type         = "email"

  labels = {
    email_address = var.notification_email
  }

  user_labels = local.common_labels
}

resource "google_monitoring_notification_channel" "slack" {
  count = var.slack_webhook_url != null ? 1 : 0

  display_name = "${var.environment} Slack Notification"
  project      = var.project_id
  type         = "slack"

  labels = {
    channel_name = var.slack_channel_name
  }

  sensitive_labels {
    auth_token = var.slack_webhook_url
  }

  user_labels = local.common_labels
}

resource "google_monitoring_notification_channel" "pagerduty" {
  count = var.pagerduty_service_key != null ? 1 : 0

  display_name = "${var.environment} PagerDuty Notification"
  project      = var.project_id
  type         = "pagerduty"

  labels = {
    service_key = var.pagerduty_service_key
  }

  user_labels = local.common_labels
}

locals {
  notification_channels = concat(
    [google_monitoring_notification_channel.email.id],
    var.slack_webhook_url != null ? [google_monitoring_notification_channel.slack[0].id] : [],
    var.pagerduty_service_key != null ? [google_monitoring_notification_channel.pagerduty[0].id] : []
  )
}

# =============================================================================
# Alert Policies
# =============================================================================

resource "google_monitoring_alert_policy" "high_cpu" {
  display_name = "${var.environment} - High CPU Utilization"
  project      = var.project_id
  combiner     = "OR"
  enabled      = var.enable_alerts

  documentation {
    content   = "CPU utilization has exceeded ${var.cpu_threshold}% for the specified duration. Please investigate the affected resource."
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "CPU utilization exceeds threshold"

    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
      duration        = var.alert_duration
      comparison      = "COMPARISON_GT"
      threshold_value = var.cpu_threshold / 100

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.label.instance_id"]
      }

      trigger {
        count = 1
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"

    notification_rate_limit {
      period = "300s"
    }
  }

  notification_channels = local.notification_channels
  user_labels           = local.common_labels
}

resource "google_monitoring_alert_policy" "high_memory" {
  display_name = "${var.environment} - High Memory Utilization"
  project      = var.project_id
  combiner     = "OR"
  enabled      = var.enable_alerts

  documentation {
    content   = "Memory utilization has exceeded ${var.memory_threshold}% for the specified duration. Consider scaling or optimizing memory usage."
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "Memory utilization exceeds threshold"

    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/memory/percent_used\" AND metric.labels.state = \"used\""
      duration        = var.alert_duration
      comparison      = "COMPARISON_GT"
      threshold_value = var.memory_threshold

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.label.instance_id"]
      }

      trigger {
        count = 1
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"

    notification_rate_limit {
      period = "300s"
    }
  }

  notification_channels = local.notification_channels
  user_labels           = local.common_labels
}

resource "google_monitoring_alert_policy" "uptime_check_failed" {
  display_name = "${var.environment} - Uptime Check Failed"
  project      = var.project_id
  combiner     = "OR"
  enabled      = var.enable_alerts && var.uptime_check_host != null

  documentation {
    content   = "The uptime check for ${var.uptime_check_host} has failed. The service may be down or unreachable."
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "Uptime check failure"

    condition_threshold {
      filter          = "resource.type = \"uptime_url\" AND metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.labels.check_id = \"${var.uptime_check_host != null ? google_monitoring_uptime_check_config.https[0].uptime_check_id : ""}\""
      duration        = "60s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_FRACTION_TRUE"
        cross_series_reducer = "REDUCE_FRACTION_TRUE"
        group_by_fields      = ["resource.label.host"]
      }

      trigger {
        count = 1
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"

    notification_rate_limit {
      period = "300s"
    }
  }

  notification_channels = local.notification_channels
  user_labels           = local.common_labels
}

resource "google_monitoring_alert_policy" "error_log_entries" {
  display_name = "${var.environment} - Error Log Entries Detected"
  project      = var.project_id
  combiner     = "OR"
  enabled      = var.enable_alerts

  documentation {
    content   = "Error log entries have exceeded the threshold. Please review the logs for details on the errors."
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "Error log entries exceed threshold"

    condition_threshold {
      filter          = "resource.type = \"global\" AND metric.type = \"logging.googleapis.com/user/${google_logging_metric.error_count.name}\""
      duration        = var.alert_duration
      comparison      = "COMPARISON_GT"
      threshold_value = var.error_log_threshold

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }

      trigger {
        count = 1
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"

    notification_rate_limit {
      period = "300s"
    }
  }

  notification_channels = local.notification_channels
  user_labels           = local.common_labels

  depends_on = [google_logging_metric.error_count]
}

# =============================================================================
# Uptime Check
# =============================================================================

resource "google_monitoring_uptime_check_config" "https" {
  count = var.uptime_check_host != null ? 1 : 0

  display_name = "${var.environment} - HTTPS Uptime Check"
  project      = var.project_id
  timeout      = var.uptime_check_timeout

  http_check {
    path           = var.uptime_check_path
    port           = 443
    use_ssl        = true
    validate_ssl   = true
    request_method = "GET"

    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.uptime_check_host
    }
  }

  content_matchers {
    content = var.uptime_check_content_match
    matcher = "CONTAINS_STRING"
  }

  period = var.uptime_check_period

  selected_regions = var.uptime_check_regions

  user_labels = local.common_labels
}

# =============================================================================
# Custom Log-based Metrics
# =============================================================================

resource "google_logging_metric" "error_count" {
  name    = "${local.resource_prefix}-error-count"
  project = var.project_id
  filter  = "severity >= ERROR"

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "Error Log Count"

    labels {
      key         = "severity"
      value_type  = "STRING"
      description = "Log severity level"
    }
  }

  label_extractors = {
    "severity" = "EXTRACT(severity)"
  }
}

resource "google_logging_metric" "latency" {
  name    = "${local.resource_prefix}-request-latency"
  project = var.project_id
  filter  = "resource.type = \"http_load_balancer\" AND httpRequest.latency != \"\""

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "DISTRIBUTION"
    unit         = "s"
    display_name = "Request Latency"
  }

  value_extractor = "EXTRACT(httpRequest.latency)"

  bucket_options {
    exponential_buckets {
      num_finite_buckets = 64
      growth_factor      = 2
      scale              = 0.01
    }
  }
}

resource "google_logging_metric" "http_status_codes" {
  name    = "${local.resource_prefix}-http-status-codes"
  project = var.project_id
  filter  = "resource.type = \"http_load_balancer\""

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "HTTP Status Codes"

    labels {
      key         = "status_code"
      value_type  = "STRING"
      description = "HTTP response status code"
    }
  }

  label_extractors = {
    "status_code" = "EXTRACT(httpRequest.status)"
  }
}

# =============================================================================
# Dashboard
# =============================================================================

resource "google_monitoring_dashboard" "main" {
  dashboard_json = templatefile("${path.module}/templates/dashboard.json", {
    dashboard_display_name = var.dashboard_display_name
    project_id             = var.project_id
    environment            = var.environment
    error_metric_name      = google_logging_metric.error_count.name
    latency_metric_name    = google_logging_metric.latency.name
    status_metric_name     = google_logging_metric.http_status_codes.name
  })

  project = var.project_id

  depends_on = [
    google_logging_metric.error_count,
    google_logging_metric.latency,
    google_logging_metric.http_status_codes
  ]
}
