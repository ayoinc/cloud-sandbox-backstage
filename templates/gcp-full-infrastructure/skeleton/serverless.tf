# =============================================================================
# Serverless: Cloud Run service
# =============================================================================

resource "google_service_account" "cloud_run" {
  count = var.enable_serverless ? 1 : 0

  account_id   = "${local.sa_prefix}-run"
  display_name = "Cloud Run service of ${local.name_prefix}"

  depends_on = [google_project_service.main]
}

# Reachable from the VPC network and through a load balancer only. No
# unauthenticated invoker is granted.
resource "google_cloud_run_v2_service" "main" {
  count = var.enable_serverless ? 1 : 0

  name        = "${local.name_prefix}-api"
  description = "Cloud Run service of ${var.project_name} (${var.environment})"
  location    = var.region
  ingress     = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  labels      = local.labels

  template {
    service_account = google_service_account.cloud_run[0].email

    scaling {
      min_instance_count = 0
      max_instance_count = local.is_production ? 10 : 2
    }

    containers {
      image = var.cloud_run_image

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }

  depends_on = [google_project_service.main]
}
