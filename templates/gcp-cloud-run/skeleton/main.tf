terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    # Configure your backend
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.region
}

locals {
  common_labels = {
    project     = var.name
    environment = var.environment
    managed-by  = "terraform"
  }
}

# Service Account for Cloud Run
resource "google_service_account" "cloudrun" {
  account_id   = "${var.name}-${var.environment}"
  display_name = "Cloud Run Service Account for ${var.name}"
}

# Artifact Registry for container images
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "${var.name}-${var.environment}"
  description   = "Container registry for ${var.name}"
  format        = "DOCKER"

  labels = local.common_labels
}

# Cloud Run Service
resource "google_cloud_run_v2_service" "main" {
  name     = "${var.name}-${var.environment}"
  location = var.region

  template {
    service_account = google_service_account.cloudrun.email

    scaling {
      min_instance_count = var.environment == "production" ? 1 : 0
      max_instance_count = var.max_instances
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.gcp_project}/${google_artifact_registry_repository.main.repository_id}/${var.name}:latest"

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle = var.environment != "production"
      }

      ports {
        container_port = 8080
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      startup_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 0
        timeout_seconds       = 1
        period_seconds        = 3
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 0
        timeout_seconds       = 1
        period_seconds        = 10
        failure_threshold     = 3
      }
    }

    labels = local.common_labels
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  labels = local.common_labels
}

# IAM - Allow unauthenticated access if enabled
resource "google_cloud_run_v2_service_iam_member" "public" {
  count    = var.allow_unauthenticated ? 1 : 0
  location = google_cloud_run_v2_service.main.location
  name     = google_cloud_run_v2_service.main.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Cloud Monitoring Alert Policy
resource "google_monitoring_alert_policy" "high_latency" {
  display_name = "${var.name}-${var.environment}-high-latency"
  combiner     = "OR"

  conditions {
    display_name = "High Latency"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${var.name}-${var.environment}\" AND metric.type = \"run.googleapis.com/request_latencies\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 1000

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
      }
    }
  }

  notification_channels = []

  alert_strategy {
    auto_close = "604800s"
  }
}

# Cloud Monitoring Alert Policy - Error Rate
resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "${var.name}-${var.environment}-high-error-rate"
  combiner     = "OR"

  conditions {
    display_name = "High Error Rate"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${var.name}-${var.environment}\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class != \"2xx\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = []

  alert_strategy {
    auto_close = "604800s"
  }
}
