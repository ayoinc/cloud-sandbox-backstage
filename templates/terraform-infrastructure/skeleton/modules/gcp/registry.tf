# Container registry of the container, ML and serverless platforms.
resource "google_artifact_registry_repository" "containers" {
  count = local.registry ? 1 : 0

  project       = var.project_id
  location      = var.region
  repository_id = "${var.name_prefix}-containers"
  description   = "Container images of the ${var.name_prefix} ${var.environment} stack"
  format        = "DOCKER"
  kms_key_name  = local.kms_key_id
  labels        = local.labels

  # A released tag always points to the same image in production.
  docker_config {
    immutable_tags = local.is_production
  }

  # Cost optimization removes untagged images after 30 days, except the ten
  # most recent versions of every image.
  dynamic "cleanup_policies" {
    for_each = var.enable_cost_optimization ? [1] : []

    content {
      id     = "delete-untagged"
      action = "DELETE"

      condition {
        tag_state  = "UNTAGGED"
        older_than = "30d"
      }
    }
  }

  dynamic "cleanup_policies" {
    for_each = var.enable_cost_optimization ? [1] : []

    content {
      id     = "keep-recent"
      action = "KEEP"

      most_recent_versions {
        keep_count = 10
      }
    }
  }

  depends_on = [time_sleep.api_propagation, time_sleep.kms_iam_propagation]
}

# The cluster nodes pull images from the registry.
resource "google_artifact_registry_repository_iam_member" "gke_nodes" {
  count = local.registry && var.enable_kubernetes ? 1 : 0

  project    = var.project_id
  location   = google_artifact_registry_repository.containers[0].location
  repository = google_artifact_registry_repository.containers[0].name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}
