mock_provider "google" {}
mock_provider "random" {}

variables {
  project_name = "acme-platform"
  environment  = "dev"
  project_id   = "acme-platform-dev"
  region       = "us-central1"
}

run "defaults" {
  command = plan

  assert {
    condition     = length(google_storage_bucket.logs) == 1 && google_storage_bucket.logs[0].public_access_prevention == "enforced" && google_storage_bucket.logs[0].uniform_bucket_level_access == true
    error_message = "The log bucket must exist and block public access."
  }

  assert {
    condition     = length(google_storage_bucket.logs[0].lifecycle_rule) == 2
    error_message = "The log bucket must archive and expire objects."
  }

  assert {
    condition     = google_logging_project_sink.archive[0].filter == "severity>=WARNING" && google_logging_project_sink.archive[0].unique_writer_identity == true
    error_message = "The sink must archive warnings and above with its own identity."
  }

  assert {
    condition     = google_logging_metric.error_count.name == "acme-platform-dev-error-count"
    error_message = "The error metric must be named after the project and environment."
  }

  assert {
    condition     = length(google_monitoring_notification_channel.email) == 0 && length(google_monitoring_notification_channel.slack) == 0 && length(google_monitoring_notification_channel.pagerduty) == 0
    error_message = "No notification channels may exist without configuration."
  }

  assert {
    condition     = length(google_monitoring_alert_policy.high_cpu) == 1 && length(google_monitoring_alert_policy.high_memory) == 1 && length(google_monitoring_alert_policy.error_logs) == 1
    error_message = "CPU, memory and error log alerts must be on by default."
  }

  assert {
    condition     = google_monitoring_alert_policy.high_cpu[0].conditions[0].condition_threshold[0].threshold_value == 0.8
    error_message = "The CPU threshold must be expressed as a fraction."
  }

  assert {
    condition     = length(google_monitoring_uptime_check_config.https) == 0 && length(google_monitoring_alert_policy.uptime) == 0
    error_message = "No uptime check or alert may exist without a host."
  }

  assert {
    condition     = length(google_monitoring_dashboard.main) == 1 && length(jsondecode(google_monitoring_dashboard.main[0].dashboard_json).mosaicLayout.tiles) == 4
    error_message = "The dashboard must show three charts and the log panel."
  }

  assert {
    condition     = jsondecode(google_monitoring_dashboard.main[0].dashboard_json).displayName == "acme-platform dev overview"
    error_message = "The dashboard title must be derived from the project name and environment."
  }
}

run "null_optional_inputs" {
  command = plan

  variables {
    notification_email     = null
    slack_auth_token       = null
    pagerduty_service_key  = null
    kms_key_id             = null
    uptime_check_host      = null
    dashboard_display_name = null
  }

  assert {
    condition     = length(output.notification_channel_ids) == 0
    error_message = "Null channel settings must create no channels."
  }
}

run "all_features" {
  command = plan

  variables {
    notification_email     = "platform-oncall@acme.example"
    slack_channel_name     = "#platform-alerts"
    slack_auth_token       = "test-slack-token"
    pagerduty_service_key  = "test-pagerduty-key"
    kms_key_id             = "projects/acme-platform-dev/locations/us-central1/keyRings/acme/cryptoKeys/acme-key"
    uptime_check_host      = "app.acme.example"
    uptime_check_path      = "/healthz"
    dashboard_display_name = "Acme platform (dev)"
    cpu_threshold_percent  = 90
  }

  assert {
    condition     = google_monitoring_notification_channel.email[0].labels["email_address"] == "platform-oncall@acme.example"
    error_message = "The email channel must use the configured address."
  }

  assert {
    condition     = google_monitoring_notification_channel.slack[0].labels["channel_name"] == "#platform-alerts" && google_monitoring_notification_channel.pagerduty[0].type == "pagerduty"
    error_message = "Slack and PagerDuty channels must be created."
  }

  assert {
    condition     = google_storage_bucket.logs[0].encryption[0].default_kms_key_name == "projects/acme-platform-dev/locations/us-central1/keyRings/acme/cryptoKeys/acme-key"
    error_message = "The log bucket must be encrypted with the given key."
  }

  assert {
    condition     = google_monitoring_uptime_check_config.https[0].http_check[0].path == "/healthz" && google_monitoring_uptime_check_config.https[0].http_check[0].validate_ssl == true
    error_message = "The uptime check must probe the configured path and validate TLS."
  }

  assert {
    condition     = google_monitoring_uptime_check_config.https[0].monitored_resource[0].labels["host"] == "app.acme.example"
    error_message = "The uptime check must probe the configured host."
  }

  assert {
    condition     = length(google_monitoring_alert_policy.uptime) == 1
    error_message = "The uptime alert must exist when a host is configured."
  }

  assert {
    condition     = google_monitoring_alert_policy.high_cpu[0].conditions[0].condition_threshold[0].threshold_value == 0.9
    error_message = "The CPU threshold must follow the input."
  }

  assert {
    condition     = length(jsondecode(google_monitoring_dashboard.main[0].dashboard_json).mosaicLayout.tiles) == 5 && jsondecode(google_monitoring_dashboard.main[0].dashboard_json).displayName == "Acme platform (dev)"
    error_message = "The dashboard must add the uptime chart and use the custom title."
  }
}

run "everything_off" {
  command = plan

  variables {
    enable_log_sink  = false
    enable_alerts    = false
    enable_dashboard = false
  }

  assert {
    condition     = length(google_storage_bucket.logs) == 0 && length(google_logging_project_sink.archive) == 0 && length(google_storage_bucket_iam_member.log_writer) == 0
    error_message = "Disabling the sink must remove the bucket, the sink and its IAM member."
  }

  assert {
    condition     = length(output.alert_policy_ids) == 0 && output.dashboard_id == null
    error_message = "Alerts and the dashboard must be removable."
  }
}

run "rejects_retention_shorter_than_archive" {
  command = plan

  variables {
    log_archive_days   = 90
    log_retention_days = 30
  }

  expect_failures = [google_storage_bucket.logs]
}
