locals {
  cluster_name = "${var.name_prefix}-gke"

  # Resource types whose logs are routed to the log bucket.
  logged_resource_types = concat(
    var.enable_kubernetes ? ["gke_cluster", "k8s_cluster", "k8s_node", "k8s_pod", "k8s_container"] : [],
    local.cloud_sql ? ["cloudsql_database"] : [],
    local.redis ? ["redis_instance"] : [],
    var.enable_cdn ? ["http_load_balancer"] : [],
    local.has_buckets ? ["gcs_bucket"] : [],
    var.enable_networking ? ["nat_gateway", "gce_subnetwork"] : [],
    local.private_dns ? ["dns_query"] : [],
  )

  log_filters = concat(
    var.require_flow_logs ? ["log_id(\"compute.googleapis.com/vpc_flows\")", "log_id(\"networkmanagement.googleapis.com/vpc_flows\")"] : [],
    var.enable_monitoring ? ["logName:\"cloudaudit.googleapis.com\""] : [],
    var.enable_monitoring && length(local.logged_resource_types) > 0 ? ["resource.type=(${join(" OR ", formatlist("\"%s\"", local.logged_resource_types))})"] : [],
  )

  # Metrics that are charted on the dashboard and alerted on. Every entry
  # compares one aligned time series with a threshold.
  metric_catalog = {
    database-cpu = {
      enabled   = local.cloud_sql
      title     = "Database CPU utilization"
      filter    = "resource.type = \"cloudsql_database\" AND resource.labels.database_id = \"${var.project_id}:${local.sql_instance_name}\" AND metric.type = \"cloudsql.googleapis.com/database/cpu/utilization\""
      aligner   = "ALIGN_MEAN"
      reducer   = "REDUCE_NONE"
      threshold = 0.8
      severity  = "WARNING"
    }
    database-disk = {
      enabled   = local.cloud_sql
      title     = "Database disk utilization"
      filter    = "resource.type = \"cloudsql_database\" AND resource.labels.database_id = \"${var.project_id}:${local.sql_instance_name}\" AND metric.type = \"cloudsql.googleapis.com/database/disk/utilization\""
      aligner   = "ALIGN_MEAN"
      reducer   = "REDUCE_NONE"
      threshold = 0.85
      severity  = "ERROR"
    }
    redis-memory = {
      enabled   = local.redis
      title     = "Redis memory usage ratio"
      filter    = "resource.type = \"redis_instance\" AND resource.labels.instance_id = \"projects/${var.project_id}/locations/${var.region}/instances/${local.redis_name}\" AND metric.type = \"redis.googleapis.com/stats/memory/usage_ratio\""
      aligner   = "ALIGN_MEAN"
      reducer   = "REDUCE_NONE"
      threshold = 0.8
      severity  = "WARNING"
    }
    cluster-node-cpu = {
      enabled   = var.enable_kubernetes
      title     = "Cluster node CPU utilization"
      filter    = "resource.type = \"k8s_node\" AND resource.labels.cluster_name = \"${local.cluster_name}\" AND metric.type = \"kubernetes.io/node/cpu/allocatable_utilization\""
      aligner   = "ALIGN_MEAN"
      reducer   = "REDUCE_NONE"
      threshold = 0.85
      severity  = "WARNING"
    }
    cluster-restarts = {
      enabled   = var.enable_kubernetes
      title     = "Container restarts in 5 minutes"
      filter    = "resource.type = \"k8s_container\" AND resource.labels.cluster_name = \"${local.cluster_name}\" AND metric.type = \"kubernetes.io/container/restart_count\""
      aligner   = "ALIGN_DELTA"
      reducer   = "REDUCE_NONE"
      threshold = 3
      severity  = "WARNING"
    }
    cdn-errors = {
      enabled   = var.enable_cdn
      title     = "CDN 5xx responses per second"
      filter    = "resource.type = \"https_lb_rule\" AND resource.labels.url_map_name = \"${var.name_prefix}-cdn\" AND metric.type = \"loadbalancing.googleapis.com/https/request_count\" AND metric.labels.response_code_class = 500"
      aligner   = "ALIGN_RATE"
      reducer   = "REDUCE_SUM"
      threshold = 1
      severity  = "ERROR"
    }
    waf-blocked = {
      enabled   = var.enable_waf
      title     = "Requests blocked by the WAF per second"
      filter    = "resource.type = \"network_security_policy\" AND resource.labels.policy_name = \"${var.name_prefix}-waf\" AND metric.type = \"networksecurity.googleapis.com/https/request_count\" AND metric.labels.blocked = \"true\""
      aligner   = "ALIGN_RATE"
      reducer   = "REDUCE_SUM"
      threshold = 5
      severity  = "WARNING"
    }
    storage-errors = {
      enabled   = local.has_buckets
      title     = "Storage server errors per second"
      filter    = "resource.type = \"gcs_bucket\" AND resource.labels.bucket_name = starts_with(\"${var.name_prefix}-\") AND metric.type = \"storage.googleapis.com/api/request_count\" AND metric.labels.response_code = one_of(\"INTERNAL\", \"UNAVAILABLE\", \"DEADLINE_EXCEEDED\")"
      aligner   = "ALIGN_RATE"
      reducer   = "REDUCE_SUM"
      threshold = 1
      severity  = "WARNING"
    }
  }
  metrics = { for name, metric in local.metric_catalog : name => metric if metric.enabled }
  alerts  = { for name, metric in local.metrics : name => metric if var.enable_alerting }

  # The volume of the log bucket is always charted.
  dashboard_charts = concat(
    [for name, metric in local.metrics : {
      title   = metric.title
      filter  = metric.filter
      aligner = metric.aligner
      reducer = metric.reducer
    }],
    [{
      title   = "Log volume ingested per second"
      filter  = "resource.type = \"global\" AND metric.type = \"logging.googleapis.com/billing/bytes_ingested\""
      aligner = "ALIGN_RATE"
      reducer = "REDUCE_SUM"
    }],
  )
}

# -----------------------------------------------------------------------------
# Logs
# -----------------------------------------------------------------------------

# A deleted log bucket keeps its name reserved for a week, so the name
# carries the random suffix.
resource "google_logging_project_bucket_config" "this" {
  count = local.log_destination ? 1 : 0

  project        = var.project_id
  location       = var.region
  bucket_id      = "${var.name_prefix}-logs-${local.suffix}"
  description    = "Logs of the ${var.name_prefix} ${var.environment} stack"
  retention_days = var.log_retention_days

  dynamic "cmek_settings" {
    for_each = var.enable_kms ? [1] : []

    content {
      kms_key_name = local.kms_key_id
    }
  }

  depends_on = [time_sleep.api_propagation, time_sleep.kms_iam_propagation]
}

# A sink to a log bucket of the same project needs no extra permissions.
resource "google_logging_project_sink" "this" {
  count = local.log_destination ? 1 : 0

  project                = var.project_id
  name                   = "${var.name_prefix}-logs"
  description            = "Routes the logs of the ${var.name_prefix} stack to its log bucket"
  destination            = "logging.googleapis.com/${google_logging_project_bucket_config.this[0].id}"
  filter                 = join(" OR ", local.log_filters)
  unique_writer_identity = true
}

# -----------------------------------------------------------------------------
# Dashboard
# -----------------------------------------------------------------------------

resource "google_monitoring_dashboard" "this" {
  count = var.enable_monitoring ? 1 : 0

  project = var.project_id

  dashboard_json = jsonencode({
    displayName = "${var.name_prefix} ${var.environment}"
    gridLayout = {
      columns = "2"
      widgets = [for chart in local.dashboard_charts : {
        title = chart.title
        xyChart = {
          dataSets = [{
            plotType = "LINE"
            timeSeriesQuery = {
              timeSeriesFilter = {
                filter = chart.filter
                aggregation = {
                  alignmentPeriod    = "300s"
                  perSeriesAligner   = chart.aligner
                  crossSeriesReducer = chart.reducer
                }
              }
            }
          }]
        }
      }]
    }
  })

  depends_on = [time_sleep.api_propagation]
}

# -----------------------------------------------------------------------------
# Managed Service for Prometheus
# -----------------------------------------------------------------------------

# Identity for tools that query the metrics, such as a self-hosted Grafana.
# Bind it to a Kubernetes service account with Workload Identity to use it.
resource "google_service_account" "prometheus_query" {
  count = var.enable_managed_prometheus ? 1 : 0

  project      = var.project_id
  account_id   = "${var.name_prefix}-prom"
  display_name = "Prometheus queries of ${var.name_prefix}"

  depends_on = [time_sleep.api_propagation]
}

resource "google_project_iam_member" "prometheus_query" {
  count = var.enable_managed_prometheus ? 1 : 0

  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.prometheus_query[0].email}"
}

# -----------------------------------------------------------------------------
# Alerting
# -----------------------------------------------------------------------------

# Every alert is published to this topic; subscribe your own tooling to it.
resource "google_pubsub_topic" "alerts" {
  count = var.enable_alerting ? 1 : 0

  project = var.project_id
  name    = "${var.name_prefix}-alerts"
  labels  = local.labels

  message_storage_policy {
    allowed_persistence_regions = [var.region]
  }

  depends_on = [time_sleep.api_propagation]
}

resource "google_monitoring_notification_channel" "pubsub" {
  count = var.enable_alerting ? 1 : 0

  project      = var.project_id
  display_name = "${var.name_prefix} alerts topic"
  type         = "pubsub"

  labels = {
    topic = google_pubsub_topic.alerts[0].id
  }
}

# Cloud Monitoring creates its notification service agent together with the
# first Pub/Sub channel, so the permission is granted after the channel.
resource "google_pubsub_topic_iam_member" "alerts_publisher" {
  count = var.enable_alerting ? 1 : 0

  project = var.project_id
  topic   = google_pubsub_topic.alerts[0].name
  role    = "roles/pubsub.publisher"
  member  = local.service_agents.alerts

  depends_on = [google_monitoring_notification_channel.pubsub]
}

resource "google_monitoring_notification_channel" "email" {
  count = var.enable_alerting && var.alert_email != null ? 1 : 0

  project      = var.project_id
  display_name = "${var.name_prefix} alerts email"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }

  depends_on = [time_sleep.api_propagation]
}

resource "google_monitoring_alert_policy" "this" {
  for_each = local.alerts

  project      = var.project_id
  display_name = "${var.name_prefix}: ${each.value.title}"
  combiner     = "OR"
  severity     = each.value.severity
  user_labels  = local.labels

  notification_channels = concat(
    google_monitoring_notification_channel.pubsub[*].id,
    google_monitoring_notification_channel.email[*].id,
  )

  conditions {
    display_name = "${each.value.title} above ${each.value.threshold}"

    condition_threshold {
      filter          = each.value.filter
      comparison      = "COMPARISON_GT"
      threshold_value = each.value.threshold
      duration        = "300s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = each.value.aligner
        cross_series_reducer = each.value.reducer
      }

      trigger {
        count = 1
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    mime_type = "text/markdown"
    content   = "${each.value.title} of the ${var.name_prefix} ${var.environment} stack stayed above ${each.value.threshold} for 5 minutes."
  }
}
