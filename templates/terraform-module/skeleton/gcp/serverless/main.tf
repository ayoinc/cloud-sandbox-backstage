locals {
  # Resource names are limited to 63 characters and service account IDs to 30,
  # so the project name is shortened before the environment is appended.
  name_prefix = "${trimsuffix(substr(var.project_name, 0, 16), "-")}-${var.environment}"

  labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })

  is_function  = var.deploy_type == "function"
  service_name = "${local.name_prefix}-${var.service_name}"

  # A 2nd gen function is served by a Cloud Run service of the same name, so
  # URL and invoker permissions are handled the same way for both types.
  service_uri = local.is_function ? google_cloudfunctions2_function.main[0].service_config[0].uri : google_cloud_run_v2_service.main[0].uri

  run_ingress = {
    all                               = "INGRESS_TRAFFIC_ALL"
    internal                          = "INGRESS_TRAFFIC_INTERNAL_ONLY"
    internal-and-cloud-load-balancing = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  }
  function_ingress = {
    all                               = "ALLOW_ALL"
    internal                          = "ALLOW_INTERNAL_ONLY"
    internal-and-cloud-load-balancing = "ALLOW_INTERNAL_AND_GCLB"
  }

  # Pub/Sub push and Cloud Scheduler call the service with their own identity.
  create_invoker = var.enable_pubsub || var.schedule_cron != null

  invoker_members = toset(concat(
    var.invoker_members,
    var.allow_unauthenticated ? ["allUsers"] : [],
  ))
}

# -----------------------------------------------------------------------------
# Runtime identity
# -----------------------------------------------------------------------------

resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = "${local.name_prefix}-run"
  display_name = "${var.project_name} ${var.environment} serverless runtime"
  description  = "Identity the ${local.service_name} service runs as"
}

resource "google_project_iam_member" "runtime" {
  for_each = toset(var.service_account_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_secret_manager_secret_iam_member" "runtime" {
  for_each = var.secret_environment_variables

  project   = var.project_id
  secret_id = each.value.secret
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.runtime.email}"
}

# -----------------------------------------------------------------------------
# Cloud Run service
# -----------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "main" {
  count = local.is_function ? 0 : 1

  project             = var.project_id
  location            = var.region
  name                = local.service_name
  description         = var.description
  ingress             = local.run_ingress[var.ingress]
  deletion_protection = var.deletion_protection
  labels              = local.labels

  template {
    service_account                  = google_service_account.runtime.email
    timeout                          = "${var.timeout_seconds}s"
    max_instance_request_concurrency = var.max_concurrency
    labels                           = local.labels

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.container_image

      ports {
        container_port = var.container_port
      }

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle          = var.cpu_idle
        startup_cpu_boost = true
      }

      dynamic "env" {
        for_each = var.environment_variables

        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secret_environment_variables

        content {
          name = env.key

          value_source {
            secret_key_ref {
              secret  = env.value.secret
              version = env.value.version
            }
          }
        }
      }

      dynamic "liveness_probe" {
        for_each = var.health_check_path == null ? [] : [var.health_check_path]

        content {
          period_seconds    = 30
          timeout_seconds   = 5
          failure_threshold = 3

          http_get {
            path = liveness_probe.value
            port = var.container_port
          }
        }
      }
    }

    dynamic "vpc_access" {
      for_each = var.vpc_connector == null ? [] : [var.vpc_connector]

      content {
        connector = vpc_access.value
        egress    = var.vpc_egress
      }
    }
  }

  depends_on = [google_secret_manager_secret_iam_member.runtime]
}

# -----------------------------------------------------------------------------
# Cloud Functions (2nd gen)
# -----------------------------------------------------------------------------

# Bucket names are global, so a random suffix keeps them unique.
resource "random_id" "source_bucket" {
  count = local.is_function ? 1 : 0

  byte_length = 4
}

resource "google_storage_bucket" "function_source" {
  count = local.is_function ? 1 : 0

  project       = var.project_id
  name          = "${local.name_prefix}-fn-src-${random_id.source_bucket[0].hex}"
  location      = var.region
  force_destroy = true
  labels        = local.labels

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      num_newer_versions = 5
      with_state         = "ARCHIVED"
    }
  }
}

resource "google_storage_bucket_object" "function_source" {
  count = local.is_function ? 1 : 0

  bucket       = google_storage_bucket.function_source[0].name
  name         = "${local.service_name}.zip"
  source       = var.source_archive_path
  content_type = "application/zip"

  lifecycle {
    precondition {
      condition     = var.source_archive_path != null
      error_message = "deploy_type = \"function\" requires source_archive_path, the path of a zip archive with the function source."
    }
  }
}

resource "google_cloudfunctions2_function" "main" {
  count = local.is_function ? 1 : 0

  project     = var.project_id
  location    = var.region
  name        = local.service_name
  description = var.description
  labels      = local.labels

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point

    # A new upload gets a new generation, which redeploys the function.
    source {
      storage_source {
        bucket     = google_storage_bucket.function_source[0].name
        object     = google_storage_bucket_object.function_source[0].name
        generation = google_storage_bucket_object.function_source[0].generation
      }
    }
  }

  service_config {
    service_account_email            = google_service_account.runtime.email
    available_cpu                    = var.cpu
    available_memory                 = var.memory
    timeout_seconds                  = var.timeout_seconds
    min_instance_count               = var.min_instances
    max_instance_count               = var.max_instances
    max_instance_request_concurrency = var.max_concurrency
    environment_variables            = var.environment_variables
    ingress_settings                 = local.function_ingress[var.ingress]
    all_traffic_on_latest_revision   = true
    vpc_connector                    = var.vpc_connector
    vpc_connector_egress_settings    = var.vpc_connector == null ? null : var.vpc_egress

    dynamic "secret_environment_variables" {
      for_each = var.secret_environment_variables

      content {
        key        = secret_environment_variables.key
        project_id = var.project_id
        secret     = secret_environment_variables.value.secret
        version    = secret_environment_variables.value.version
      }
    }
  }

  depends_on = [google_secret_manager_secret_iam_member.runtime]
}

# -----------------------------------------------------------------------------
# Who may call the service
# -----------------------------------------------------------------------------

resource "google_cloud_run_v2_service_iam_member" "invokers" {
  for_each = local.invoker_members

  project  = var.project_id
  location = var.region
  name     = local.service_name
  role     = "roles/run.invoker"
  member   = each.value

  depends_on = [google_cloud_run_v2_service.main, google_cloudfunctions2_function.main]
}

resource "google_service_account" "invoker" {
  count = local.create_invoker ? 1 : 0

  project      = var.project_id
  account_id   = "${local.name_prefix}-call"
  display_name = "${var.project_name} ${var.environment} serverless invoker"
  description  = "Identity Pub/Sub and Cloud Scheduler use to call ${local.service_name}"
}

resource "google_cloud_run_v2_service_iam_member" "invoker_service_account" {
  count = local.create_invoker ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = local.service_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.invoker[0].email}"

  depends_on = [google_cloud_run_v2_service.main, google_cloudfunctions2_function.main]
}

# -----------------------------------------------------------------------------
# Pub/Sub trigger
# -----------------------------------------------------------------------------

resource "google_pubsub_topic" "main" {
  count = var.enable_pubsub ? 1 : 0

  project                    = var.project_id
  name                       = "${local.service_name}-events"
  message_retention_duration = var.pubsub_message_retention_duration
  kms_key_name               = var.kms_key_id
  labels                     = local.labels
}

resource "google_pubsub_subscription" "push" {
  count = var.enable_pubsub ? 1 : 0

  project              = var.project_id
  name                 = "${local.service_name}-push"
  topic                = google_pubsub_topic.main[0].id
  ack_deadline_seconds = var.pubsub_ack_deadline_seconds
  labels               = local.labels

  push_config {
    push_endpoint = local.service_uri

    oidc_token {
      service_account_email = google_service_account.invoker[0].email
    }
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  # An empty TTL keeps the subscription even when it is idle.
  expiration_policy {
    ttl = ""
  }

  depends_on = [google_cloud_run_v2_service_iam_member.invoker_service_account]
}

# -----------------------------------------------------------------------------
# Schedule
# -----------------------------------------------------------------------------

resource "google_cloud_scheduler_job" "main" {
  count = var.schedule_cron == null ? 0 : 1

  project          = var.project_id
  region           = var.region
  name             = "${local.service_name}-schedule"
  description      = "Calls ${local.service_name} on a schedule"
  schedule         = var.schedule_cron
  time_zone        = var.schedule_time_zone
  attempt_deadline = "${min(var.timeout_seconds, 1800)}s"

  http_target {
    uri         = local.service_uri
    http_method = "POST"

    oidc_token {
      service_account_email = google_service_account.invoker[0].email
      audience              = local.service_uri
    }
  }

  retry_config {
    retry_count = 3
  }

  depends_on = [google_cloud_run_v2_service_iam_member.invoker_service_account]
}
