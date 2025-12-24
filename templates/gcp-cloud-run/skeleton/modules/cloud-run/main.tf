# =============================================================================
# GCP Cloud Run Module - Main Configuration
# =============================================================================
# Creates a Cloud Run service with:
# - Service Account with appropriate permissions
# - Artifact Registry for container images
# - Cloud Run service with configurable scaling
# - Health checks and probes
# - Optional public access
# - Monitoring alert policies
# - VPC connector support (optional)
# - Secret Manager integration (optional)
# =============================================================================

locals {
  # Naming convention: {name}-{environment}
  service_name = "${var.name}-${var.environment}"
  sa_name      = "${var.name}-${var.environment}-run"

  # Common labels for all resources
  common_labels = merge(
    {
      project     = var.name
      environment = var.environment
      managed-by  = "terraform"
      owner       = replace(var.owner, "/", "-")
    },
    var.labels
  )

  # Determine if this is production (for security settings)
  is_production = contains(["prod", "production"], var.environment)
}

# =============================================================================
# Service Account for Cloud Run
# =============================================================================
resource "google_service_account" "cloud_run" {
  account_id   = local.sa_name
  display_name = "Cloud Run Service Account for ${var.name}"
  description  = "Service account for Cloud Run service in ${var.name}"
}

# IAM bindings for service account
resource "google_project_iam_member" "cloud_run" {
  for_each = toset(var.service_account_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.cloud_run.email}"
}

# =============================================================================
# Artifact Registry
# =============================================================================
resource "google_artifact_registry_repository" "main" {
  count = var.create_artifact_registry ? 1 : 0

  location      = var.region
  repository_id = local.service_name
  description   = "Container registry for ${var.name}"
  format        = "DOCKER"

  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = var.artifact_registry_keep_count
    }
  }

  labels = local.common_labels
}

# =============================================================================
# VPC Access Connector (Optional)
# =============================================================================
resource "google_vpc_access_connector" "main" {
  count = var.create_vpc_connector ? 1 : 0

  name          = "${local.service_name}-connector"
  region        = var.region
  network       = var.vpc_connector_network
  ip_cidr_range = var.vpc_connector_cidr
  min_instances = var.vpc_connector_min_instances
  max_instances = var.vpc_connector_max_instances
}

# =============================================================================
# Cloud Run Service
# =============================================================================
resource "google_cloud_run_v2_service" "main" {
  name     = local.service_name
  location = var.region

  ingress = var.ingress

  template {
    service_account = google_service_account.cloud_run.email

    # VPC Access
    dynamic "vpc_access" {
      for_each = var.create_vpc_connector ? [1] : []
      content {
        connector = google_vpc_access_connector.main[0].id
        egress    = var.vpc_egress
      }
    }

    # Scaling configuration
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    # Execution environment
    execution_environment = var.execution_environment
    timeout               = "${var.request_timeout}s"

    containers {
      image = var.container_image != "" ? var.container_image : (
        var.create_artifact_registry ? (
          "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main[0].repository_id}/${var.name}:${var.image_tag}"
        ) : "gcr.io/cloudrun/hello"
      )

      # Resource limits
      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle          = var.cpu_idle
        startup_cpu_boost = var.startup_cpu_boost
      }

      # Container port
      ports {
        name           = "http1"
        container_port = var.container_port
      }

      # Environment variables
      dynamic "env" {
        for_each = merge(
          {
            ENVIRONMENT = var.environment
            SERVICE     = var.name
          },
          var.environment_variables
        )
        content {
          name  = env.key
          value = env.value
        }
      }

      # Secret environment variables
      dynamic "env" {
        for_each = var.secret_environment_variables
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret_name
              version = env.value.version
            }
          }
        }
      }

      # Volume mounts
      dynamic "volume_mounts" {
        for_each = var.volume_mounts
        content {
          name       = volume_mounts.key
          mount_path = volume_mounts.value
        }
      }

      # Startup probe
      dynamic "startup_probe" {
        for_each = var.enable_startup_probe ? [1] : []
        content {
          http_get {
            path = var.health_check_path
            port = var.container_port
          }
          initial_delay_seconds = var.startup_probe_initial_delay
          timeout_seconds       = var.startup_probe_timeout
          period_seconds        = var.startup_probe_period
          failure_threshold     = var.startup_probe_failure_threshold
        }
      }

      # Liveness probe
      dynamic "liveness_probe" {
        for_each = var.enable_liveness_probe ? [1] : []
        content {
          http_get {
            path = var.health_check_path
            port = var.container_port
          }
          initial_delay_seconds = var.liveness_probe_initial_delay
          timeout_seconds       = var.liveness_probe_timeout
          period_seconds        = var.liveness_probe_period
          failure_threshold     = var.liveness_probe_failure_threshold
        }
      }
    }

    # Volumes
    dynamic "volumes" {
      for_each = var.secret_volumes
      content {
        name = volumes.key
        secret {
          secret = volumes.value.secret_name
          items {
            path    = volumes.value.path
            version = volumes.value.version
          }
        }
      }
    }

    labels = local.common_labels
  }

  # Traffic configuration
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      # Ignore changes to image tag to allow external deployments
      template[0].containers[0].image,
    ]
  }
}

# =============================================================================
# IAM - Public Access (Optional)
# =============================================================================
resource "google_cloud_run_v2_service_iam_member" "public" {
  count    = var.allow_unauthenticated ? 1 : 0
  location = google_cloud_run_v2_service.main.location
  name     = google_cloud_run_v2_service.main.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# =============================================================================
# Cloud Monitoring - High Latency Alert
# =============================================================================
resource "google_monitoring_alert_policy" "high_latency" {
  count        = var.enable_monitoring_alerts ? 1 : 0
  display_name = "${local.service_name}-high-latency"
  combiner     = "OR"

  conditions {
    display_name = "High Latency (P99 > ${var.latency_threshold_ms}ms)"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${local.service_name}\" AND metric.type = \"run.googleapis.com/request_latencies\""
      duration        = "${var.alert_duration_seconds}s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.latency_threshold_ms

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "604800s"
  }

  user_labels = local.common_labels
}

# =============================================================================
# Cloud Monitoring - High Error Rate Alert
# =============================================================================
resource "google_monitoring_alert_policy" "high_error_rate" {
  count        = var.enable_monitoring_alerts ? 1 : 0
  display_name = "${local.service_name}-high-error-rate"
  combiner     = "OR"

  conditions {
    display_name = "High Error Rate (> ${var.error_rate_threshold}/min)"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${local.service_name}\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class != \"2xx\""
      duration        = "${var.alert_duration_seconds}s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.error_rate_threshold

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "604800s"
  }

  user_labels = local.common_labels
}

# =============================================================================
# Cloud Monitoring - Instance Count Alert
# =============================================================================
resource "google_monitoring_alert_policy" "high_instance_count" {
  count        = var.enable_monitoring_alerts && var.max_instances > 0 ? 1 : 0
  display_name = "${local.service_name}-high-instance-count"
  combiner     = "OR"

  conditions {
    display_name = "High Instance Count (> ${floor(var.max_instances * 0.8)})"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${local.service_name}\" AND metric.type = \"run.googleapis.com/container/instance_count\""
      duration        = "${var.alert_duration_seconds}s"
      comparison      = "COMPARISON_GT"
      threshold_value = floor(var.max_instances * 0.8)

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "604800s"
  }

  user_labels = local.common_labels
}
