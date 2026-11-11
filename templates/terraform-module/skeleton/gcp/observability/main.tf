locals {
  # Resource names are limited to 63 characters and service account IDs to 30,
  # so the project name is shortened before the environment is appended.
  name_prefix = "${trimsuffix(substr(var.project_name, 0, 16), "-")}-${var.environment}"

  labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })

  # Channel credentials are sensitive, but whether they are set is not.
  enable_slack     = nonsensitive(var.slack_auth_token != null)
  enable_pagerduty = nonsensitive(var.pagerduty_service_key != null)

  notification_channel_ids = concat(
    google_monitoring_notification_channel.email[*].id,
    google_monitoring_notification_channel.slack[*].id,
    google_monitoring_notification_channel.pagerduty[*].id,
  )

  error_metric_name = "${local.name_prefix}-error-count"

  cpu_filter    = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\""
  memory_filter = "metric.type=\"agent.googleapis.com/memory/percent_used\" AND resource.type=\"gce_instance\" AND metric.label.state=\"used\""

  dashboard_charts = concat(
    [
      {
        title  = "VM CPU utilization"
        filter = local.cpu_filter
        align  = "ALIGN_MEAN"
      },
      {
        title  = "VM memory used (%)"
        filter = local.memory_filter
        align  = "ALIGN_MEAN"
      },
      {
        title  = "Error log entries from VMs"
        filter = "metric.type=\"logging.googleapis.com/user/${local.error_metric_name}\" AND resource.type=\"gce_instance\""
        align  = "ALIGN_RATE"
      },
    ],
    var.uptime_check_host == null ? [] : [
      {
        title  = "Uptime check latency"
        filter = "metric.type=\"monitoring.googleapis.com/uptime_check/request_latency\" AND resource.type=\"uptime_url\""
        align  = "ALIGN_MEAN"
      },
    ],
  )
}

# -----------------------------------------------------------------------------
# Log archive
# -----------------------------------------------------------------------------

# Bucket names are global, so a random suffix keeps them unique.
resource "random_id" "bucket" {
  byte_length = 4
}

resource "google_storage_bucket" "logs" {
  count = var.enable_log_sink ? 1 : 0

  project       = var.project_id
  name          = "${local.name_prefix}-logs-${random_id.bucket.hex}"
  location      = var.region
  storage_class = "STANDARD"
  force_destroy = var.force_destroy_log_bucket
  labels        = local.labels

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  dynamic "encryption" {
    for_each = var.kms_key_id == null ? [] : [var.kms_key_id]

    content {
      default_kms_key_name = encryption.value
    }
  }

  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }

    condition {
      age = var.log_archive_days
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age = var.log_retention_days
    }
  }

  lifecycle {
    precondition {
      condition     = var.log_retention_days > var.log_archive_days
      error_message = "log_retention_days must be greater than log_archive_days."
    }
  }
}

resource "google_logging_project_sink" "archive" {
  count = var.enable_log_sink ? 1 : 0

  project                = var.project_id
  name                   = "${local.name_prefix}-log-archive"
  description            = "Archives matching log entries to Cloud Storage"
  destination            = "storage.googleapis.com/${google_storage_bucket.logs[0].name}"
  filter                 = var.log_filter
  unique_writer_identity = true
}

resource "google_storage_bucket_iam_member" "log_writer" {
  count = var.enable_log_sink ? 1 : 0

  bucket = google_storage_bucket.logs[0].name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.archive[0].writer_identity
}

# -----------------------------------------------------------------------------
# Log-based metric
# -----------------------------------------------------------------------------

resource "google_logging_metric" "error_count" {
  project     = var.project_id
  name        = local.error_metric_name
  description = "Log entries with severity ERROR or higher"
  filter      = "severity>=ERROR"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

# -----------------------------------------------------------------------------
# Notification channels
# -----------------------------------------------------------------------------

resource "google_monitoring_notification_channel" "email" {
  count = var.notification_email == null ? 0 : 1

  project      = var.project_id
  display_name = "${local.name_prefix} email"
  type         = "email"
  user_labels  = local.labels

  labels = {
    email_address = var.notification_email
  }
}

resource "google_monitoring_notification_channel" "slack" {
  count = local.enable_slack ? 1 : 0

  project      = var.project_id
  display_name = "${local.name_prefix} Slack"
  type         = "slack"
  user_labels  = local.labels

  labels = {
    channel_name = var.slack_channel_name
  }

  sensitive_labels {
    auth_token = var.slack_auth_token
  }
}

resource "google_monitoring_notification_channel" "pagerduty" {
  count = local.enable_pagerduty ? 1 : 0

  project      = var.project_id
  display_name = "${local.name_prefix} PagerDuty"
  type         = "pagerduty"
  user_labels  = local.labels

  sensitive_labels {
    service_key = var.pagerduty_service_key
  }
}

# -----------------------------------------------------------------------------
# Uptime check
# -----------------------------------------------------------------------------

resource "google_monitoring_uptime_check_config" "https" {
  count = var.uptime_check_host == null ? 0 : 1

  project      = var.project_id
  display_name = "${local.name_prefix} HTTPS uptime"
  timeout      = "${var.uptime_check_timeout_seconds}s"
  period       = "${var.uptime_check_period_seconds}s"
  user_labels  = local.labels

  http_check {
    path         = var.uptime_check_path
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"

    labels = {
      project_id = var.project_id
      host       = var.uptime_check_host
    }
  }
}

# -----------------------------------------------------------------------------
# Alert policies
# -----------------------------------------------------------------------------

resource "google_monitoring_alert_policy" "high_cpu" {
  count = var.enable_alerts ? 1 : 0

  project               = var.project_id
  display_name          = "${local.name_prefix} high CPU"
  combiner              = "OR"
  notification_channels = local.notification_channel_ids
  user_labels           = local.labels

  conditions {
    display_name = "VM CPU utilization above ${var.cpu_threshold_percent}%"

    condition_threshold {
      filter          = local.cpu_filter
      comparison      = "COMPARISON_GT"
      threshold_value = var.cpu_threshold_percent / 100
      duration        = "${var.alert_duration_seconds}s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  documentation {
    mime_type = "text/markdown"
    content   = "CPU utilization of a VM in ${var.project_id} (${var.environment}) stayed above ${var.cpu_threshold_percent}% for ${var.alert_duration_seconds} seconds."
  }
}

resource "google_monitoring_alert_policy" "high_memory" {
  count = var.enable_alerts ? 1 : 0

  project               = var.project_id
  display_name          = "${local.name_prefix} high memory"
  combiner              = "OR"
  notification_channels = local.notification_channel_ids
  user_labels           = local.labels

  conditions {
    display_name = "VM memory used above ${var.memory_threshold_percent}%"

    condition_threshold {
      filter          = local.memory_filter
      comparison      = "COMPARISON_GT"
      threshold_value = var.memory_threshold_percent
      duration        = "${var.alert_duration_seconds}s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  documentation {
    mime_type = "text/markdown"
    content   = "Memory use of a VM in ${var.project_id} (${var.environment}) stayed above ${var.memory_threshold_percent}% for ${var.alert_duration_seconds} seconds. The metric is reported by the Ops Agent."
  }
}

resource "google_monitoring_alert_policy" "error_logs" {
  count = var.enable_alerts ? 1 : 0

  project               = var.project_id
  display_name          = "${local.name_prefix} error logs"
  combiner              = "OR"
  notification_channels = local.notification_channel_ids
  user_labels           = local.labels

  conditions {
    display_name = "Log entry with severity ERROR or higher"

    condition_matched_log {
      filter = "severity>=ERROR"
    }
  }

  # Log-match conditions must be rate limited; one notification per period at most.
  alert_strategy {
    auto_close = "1800s"

    notification_rate_limit {
      period = "${var.error_log_notification_period_seconds}s"
    }
  }

  documentation {
    mime_type = "text/markdown"
    content   = "A log entry with severity ERROR or higher was written in ${var.project_id} (${var.environment})."
  }
}

resource "google_monitoring_alert_policy" "uptime" {
  count = var.enable_alerts && var.uptime_check_host != null ? 1 : 0

  project               = var.project_id
  display_name          = "${local.name_prefix} uptime check failing"
  combiner              = "OR"
  notification_channels = local.notification_channel_ids
  user_labels           = local.labels

  conditions {
    display_name = "Uptime check failing from more than one region"

    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"uptime_url\" AND metric.label.check_id=\"${google_monitoring_uptime_check_config.https[0].uptime_check_id}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1
      duration        = "${var.uptime_check_period_seconds}s"

      aggregations {
        alignment_period     = "1200s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.host"]
      }

      trigger {
        count = 1
      }
    }
  }

  documentation {
    mime_type = "text/markdown"
    content   = "The HTTPS uptime check for ${var.uptime_check_host}${var.uptime_check_path} is failing from more than one region."
  }
}

# -----------------------------------------------------------------------------
# Dashboard
# -----------------------------------------------------------------------------

resource "google_monitoring_dashboard" "main" {
  count = var.enable_dashboard ? 1 : 0

  project = var.project_id

  dashboard_json = jsonencode({
    displayName = coalesce(var.dashboard_display_name, "${var.project_name} ${var.environment} overview")

    mosaicLayout = {
      columns = 12
      tiles = concat(
        [
          for index, chart in local.dashboard_charts : {
            xPos   = (index % 2) * 6
            yPos   = floor(index / 2) * 4
            width  = 6
            height = 4
            widget = {
              title = chart.title
              xyChart = {
                dataSets = [
                  {
                    plotType = "LINE"
                    timeSeriesQuery = {
                      timeSeriesFilter = {
                        filter = chart.filter
                        aggregation = {
                          alignmentPeriod  = "60s"
                          perSeriesAligner = chart.align
                        }
                      }
                    }
                  },
                ]
              }
            }
          }
        ],
        [
          {
            xPos   = 0
            yPos   = ceil(length(local.dashboard_charts) / 2) * 4
            width  = 12
            height = 4
            widget = {
              title = "Recent errors"
              logsPanel = {
                filter        = "severity>=ERROR"
                resourceNames = ["projects/${var.project_id}"]
              }
            }
          },
        ],
      )
    }
  })
}
