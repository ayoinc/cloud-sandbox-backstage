# -----------------------------------------------------------------------------
# GCP Serverless Module - Main Resources
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_id}-${var.environment}"

  default_labels = {
    project     = var.project_id
    environment = var.environment
    managed_by  = "terraform"
  }

  labels = merge(local.default_labels, var.labels)
}

# -----------------------------------------------------------------------------
# Service Account for Cloud Function/Run
# -----------------------------------------------------------------------------

resource "google_service_account" "serverless" {
  account_id   = "${local.name_prefix}-serverless-sa"
  display_name = "Service account for ${local.name_prefix} serverless workloads"
  project      = var.project_id
  description  = "Managed by Terraform - Service account for Cloud Functions and Cloud Run"
}

# IAM Roles for Service Account
resource "google_project_iam_member" "serverless_roles" {
  for_each = toset(var.service_account_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.serverless.email}"
}

# -----------------------------------------------------------------------------
# Cloud Storage Bucket for Function Source
# -----------------------------------------------------------------------------

resource "google_storage_bucket" "function_source" {
  name     = "${local.name_prefix}-function-source"
  project  = var.project_id
  location = var.region

  uniform_bucket_level_access = true
  force_destroy               = var.environment != "prod"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  labels = local.labels
}

# Source Code Upload
resource "google_storage_bucket_object" "function_source" {
  name   = "${var.function_name}-${var.source_archive_hash}.zip"
  bucket = google_storage_bucket.function_source.name
  source = var.source_archive_path

  depends_on = [google_storage_bucket.function_source]
}

# -----------------------------------------------------------------------------
# Cloud Functions (2nd Gen)
# -----------------------------------------------------------------------------

resource "google_cloudfunctions2_function" "main" {
  count = var.deploy_type == "function" ? 1 : 0

  name     = "${local.name_prefix}-${var.function_name}"
  project  = var.project_id
  location = var.region

  description = var.description != "" ? var.description : "Managed by Terraform - ${var.function_name}"

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point

    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_source.name
      }
    }

    environment_variables = var.build_environment_variables
  }

  service_config {
    available_memory      = var.memory
    timeout_seconds       = var.timeout_seconds
    max_instance_count    = var.max_instances
    min_instance_count    = var.min_instances
    available_cpu         = var.cpu
    service_account_email = google_service_account.serverless.email

    environment_variables = var.environment_variables
    secret_environment_variables = [
      for secret in var.secret_environment_variables : {
        key        = secret.key
        project_id = var.project_id
        secret     = secret.secret_name
        version    = secret.version
      }
    ]

    ingress_settings               = var.ingress_settings
    all_traffic_on_latest_revision = true

    dynamic "vpc_connector_egress_settings" {
      for_each = var.vpc_connector != "" ? [1] : []
      content {
      }
    }

    vpc_connector = var.vpc_connector != "" ? var.vpc_connector : null
  }

  # Event Trigger (optional - for Pub/Sub, Cloud Storage, etc.)
  dynamic "event_trigger" {
    for_each = var.event_trigger != null ? [var.event_trigger] : []
    content {
      trigger_region        = var.region
      event_type            = event_trigger.value.event_type
      pubsub_topic          = event_trigger.value.pubsub_topic
      retry_policy          = event_trigger.value.retry_policy
      service_account_email = google_service_account.serverless.email

      dynamic "event_filters" {
        for_each = event_trigger.value.event_filters != null ? event_trigger.value.event_filters : []
        content {
          attribute = event_filters.value.attribute
          value     = event_filters.value.value
          operator  = event_filters.value.operator
        }
      }
    }
  }

  labels = local.labels

  depends_on = [
    google_project_iam_member.serverless_roles
  ]
}

# -----------------------------------------------------------------------------
# Cloud Run Service (Alternative to Functions)
# -----------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "main" {
  count = var.deploy_type == "run" ? 1 : 0

  name     = "${local.name_prefix}-${var.function_name}"
  project  = var.project_id
  location = var.region

  description = var.description != "" ? var.description : "Managed by Terraform - ${var.function_name}"

  ingress = var.ingress_settings == "ALLOW_ALL" ? "INGRESS_TRAFFIC_ALL" : (
    var.ingress_settings == "ALLOW_INTERNAL_ONLY" ? "INGRESS_TRAFFIC_INTERNAL_ONLY" : "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  )

  template {
    service_account = google_service_account.serverless.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    timeout = "${var.timeout_seconds}s"

    containers {
      image = var.container_image

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle          = var.cpu_idle
        startup_cpu_boost = var.startup_cpu_boost
      }

      dynamic "ports" {
        for_each = var.container_port != null ? [var.container_port] : []
        content {
          container_port = ports.value
        }
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
          name = env.value.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret_name
              version = env.value.version
            }
          }
        }
      }

      dynamic "startup_probe" {
        for_each = var.startup_probe != null ? [var.startup_probe] : []
        content {
          initial_delay_seconds = startup_probe.value.initial_delay_seconds
          timeout_seconds       = startup_probe.value.timeout_seconds
          period_seconds        = startup_probe.value.period_seconds
          failure_threshold     = startup_probe.value.failure_threshold

          dynamic "http_get" {
            for_each = startup_probe.value.http_get != null ? [startup_probe.value.http_get] : []
            content {
              path = http_get.value.path
              port = http_get.value.port
            }
          }

          dynamic "tcp_socket" {
            for_each = startup_probe.value.tcp_socket != null ? [startup_probe.value.tcp_socket] : []
            content {
              port = tcp_socket.value.port
            }
          }
        }
      }

      dynamic "liveness_probe" {
        for_each = var.liveness_probe != null ? [var.liveness_probe] : []
        content {
          initial_delay_seconds = liveness_probe.value.initial_delay_seconds
          timeout_seconds       = liveness_probe.value.timeout_seconds
          period_seconds        = liveness_probe.value.period_seconds
          failure_threshold     = liveness_probe.value.failure_threshold

          dynamic "http_get" {
            for_each = liveness_probe.value.http_get != null ? [liveness_probe.value.http_get] : []
            content {
              path = http_get.value.path
              port = http_get.value.port
            }
          }
        }
      }
    }

    dynamic "vpc_access" {
      for_each = var.vpc_connector != "" ? [1] : []
      content {
        connector = var.vpc_connector
        egress    = var.vpc_egress
      }
    }

    max_instance_request_concurrency = var.max_concurrency
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  labels = local.labels

  depends_on = [
    google_project_iam_member.serverless_roles
  ]
}

# IAM for Cloud Run Invoker Access
resource "google_cloud_run_service_iam_member" "invoker" {
  count = var.deploy_type == "run" && var.allow_unauthenticated ? 1 : 0

  project  = var.project_id
  location = var.region
  service  = google_cloud_run_v2_service.main[0].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "authenticated_invokers" {
  for_each = var.deploy_type == "run" ? toset(var.invoker_members) : []

  project  = var.project_id
  location = var.region
  service  = google_cloud_run_v2_service.main[0].name
  role     = "roles/run.invoker"
  member   = each.value
}

# IAM for Cloud Functions Invoker Access
resource "google_cloudfunctions2_function_iam_member" "invoker" {
  count = var.deploy_type == "function" && var.allow_unauthenticated ? 1 : 0

  project        = var.project_id
  location       = var.region
  cloud_function = google_cloudfunctions2_function.main[0].name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

resource "google_cloudfunctions2_function_iam_member" "authenticated_invokers" {
  for_each = var.deploy_type == "function" ? toset(var.invoker_members) : []

  project        = var.project_id
  location       = var.region
  cloud_function = google_cloudfunctions2_function.main[0].name
  role           = "roles/cloudfunctions.invoker"
  member         = each.value
}

# -----------------------------------------------------------------------------
# API Gateway (Optional)
# -----------------------------------------------------------------------------

resource "google_api_gateway_api" "main" {
  count = var.enable_api_gateway ? 1 : 0

  provider     = google-beta
  project      = var.project_id
  api_id       = "${local.name_prefix}-api"
  display_name = "${local.name_prefix} API Gateway"

  labels = local.labels
}

resource "google_api_gateway_api_config" "main" {
  count = var.enable_api_gateway ? 1 : 0

  provider             = google-beta
  project              = var.project_id
  api                  = google_api_gateway_api.main[0].api_id
  api_config_id_prefix = "${local.name_prefix}-config-"
  display_name         = "${local.name_prefix} API Config"

  openapi_documents {
    document {
      path     = "openapi.yaml"
      contents = base64encode(var.api_gateway_openapi_spec)
    }
  }

  gateway_config {
    backend_config {
      google_service_account = google_service_account.serverless.email
    }
  }

  labels = local.labels

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_api_gateway_gateway" "main" {
  count = var.enable_api_gateway ? 1 : 0

  provider     = google-beta
  project      = var.project_id
  region       = var.region
  gateway_id   = "${local.name_prefix}-gateway"
  api_config   = google_api_gateway_api_config.main[0].id
  display_name = "${local.name_prefix} Gateway"

  labels = local.labels
}

# -----------------------------------------------------------------------------
# Pub/Sub (Optional)
# -----------------------------------------------------------------------------

resource "google_pubsub_topic" "main" {
  count = var.enable_pubsub ? 1 : 0

  name    = "${local.name_prefix}-${var.function_name}-topic"
  project = var.project_id

  message_retention_duration = var.pubsub_message_retention_duration

  dynamic "schema_settings" {
    for_each = var.pubsub_schema != null ? [var.pubsub_schema] : []
    content {
      schema   = schema_settings.value.schema
      encoding = schema_settings.value.encoding
    }
  }

  labels = local.labels
}

resource "google_pubsub_subscription" "main" {
  count = var.enable_pubsub ? 1 : 0

  name    = "${local.name_prefix}-${var.function_name}-subscription"
  project = var.project_id
  topic   = google_pubsub_topic.main[0].id

  ack_deadline_seconds       = var.pubsub_ack_deadline_seconds
  message_retention_duration = var.pubsub_subscription_retention_duration
  retain_acked_messages      = var.pubsub_retain_acked_messages
  enable_message_ordering    = var.pubsub_enable_message_ordering

  expiration_policy {
    ttl = var.pubsub_subscription_expiration_ttl
  }

  retry_policy {
    minimum_backoff = var.pubsub_retry_minimum_backoff
    maximum_backoff = var.pubsub_retry_maximum_backoff
  }

  dynamic "push_config" {
    for_each = var.pubsub_push_endpoint != "" ? [1] : []
    content {
      push_endpoint = var.pubsub_push_endpoint

      oidc_token {
        service_account_email = google_service_account.serverless.email
      }

      attributes = var.pubsub_push_attributes
    }
  }

  dynamic "dead_letter_policy" {
    for_each = var.pubsub_dead_letter_topic != "" ? [1] : []
    content {
      dead_letter_topic     = var.pubsub_dead_letter_topic
      max_delivery_attempts = var.pubsub_max_delivery_attempts
    }
  }

  labels = local.labels
}

# -----------------------------------------------------------------------------
# Cloud Scheduler Job (Optional - for Scheduled Execution)
# -----------------------------------------------------------------------------

resource "google_cloud_scheduler_job" "main" {
  count = var.schedule_cron != "" ? 1 : 0

  name        = "${local.name_prefix}-${var.function_name}-scheduler"
  project     = var.project_id
  region      = var.region
  description = "Scheduled trigger for ${var.function_name}"

  schedule  = var.schedule_cron
  time_zone = var.schedule_timezone

  attempt_deadline = var.schedule_attempt_deadline

  retry_config {
    retry_count          = var.schedule_retry_count
    max_retry_duration   = var.schedule_max_retry_duration
    min_backoff_duration = var.schedule_min_backoff_duration
    max_backoff_duration = var.schedule_max_backoff_duration
    max_doublings        = var.schedule_max_doublings
  }

  dynamic "http_target" {
    for_each = var.deploy_type == "run" || (var.deploy_type == "function" && var.event_trigger == null) ? [1] : []
    content {
      uri         = var.deploy_type == "run" ? google_cloud_run_v2_service.main[0].uri : google_cloudfunctions2_function.main[0].url
      http_method = var.schedule_http_method
      body        = var.schedule_http_body != "" ? base64encode(var.schedule_http_body) : null
      headers     = var.schedule_http_headers

      oidc_token {
        service_account_email = google_service_account.serverless.email
        audience              = var.deploy_type == "run" ? google_cloud_run_v2_service.main[0].uri : google_cloudfunctions2_function.main[0].url
      }
    }
  }

  dynamic "pubsub_target" {
    for_each = var.enable_pubsub && var.schedule_use_pubsub ? [1] : []
    content {
      topic_name = google_pubsub_topic.main[0].id
      data       = var.schedule_pubsub_data != "" ? base64encode(var.schedule_pubsub_data) : null
      attributes = var.schedule_pubsub_attributes
    }
  }
}
