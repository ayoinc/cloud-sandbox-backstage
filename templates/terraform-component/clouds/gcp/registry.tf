# -----------------------------------------------------------------------------
# Container registry: Artifact Registry repository for container images
# -----------------------------------------------------------------------------

variable "registry_image_retention_count" {
  description = "Number of versions kept per image; older ones are deleted."
  type        = number
  default     = 30
}

resource "google_project_service" "artifact_registry" {
  project            = local.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "this" {
  project       = local.project_id
  location      = var.region
  repository_id = module.naming.standard["ar"]
  description   = "Container images of the ${var.component_name} component"
  format        = "DOCKER"

  docker_config {
    immutable_tags = true
  }

  cleanup_policies {
    id     = "keep-newest"
    action = "KEEP"

    most_recent_versions {
      keep_count = var.registry_image_retention_count
    }
  }

  cleanup_policies {
    id     = "delete-older"
    action = "DELETE"

    condition {
      older_than = "30d"
    }
  }

  depends_on = [google_project_service.artifact_registry]
}

output "container_registry_url" {
  description = "URL to push and pull container images."
  value       = "${var.region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.this.repository_id}"
}
