terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

locals {
  labels = merge(
    {
      project     = var.project_name
      environment = var.environment
      managed_by  = "terraform"
    },
    var.labels
  )

  create_bucket       = var.source_bucket == null && var.source_dir != null
  source_bucket_name  = local.create_bucket ? google_storage_bucket.source[0].name : var.source_bucket
  source_archive_name = var.source_archive_object != null ? var.source_archive_object : "${var.function_name}-${formatdate("YYYYMMDDhhmmss", timestamp())}.zip"
}

# Optional: Create storage bucket for source code
resource "google_storage_bucket" "source" {
  count = local.create_bucket ? 1 : 0

  project                     = var.project_id
  name                        = "${var.project_id}-${var.function_name}-source"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = true
  }

  labels = local.labels
}

# Archive the source code if source_dir is provided
data "archive_file" "source" {
  count = var.source_dir != null ? 1 : 0

  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/tmp/${var.function_name}-source.zip"
}

# Upload source code to bucket
resource "google_storage_bucket_object" "source" {
  count = var.source_dir != null ? 1 : 0

  name   = local.source_archive_name
  bucket = local.source_bucket_name
  source = data.archive_file.source[0].output_path

  depends_on = [google_storage_bucket.source]
}

# Cloud Function (2nd Gen)
resource "google_cloudfunctions2_function" "function" {
  project     = var.project_id
  name        = var.function_name
  location    = var.region
  description = var.description

  labels = local.labels

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point

    source {
      storage_source {
        bucket = local.source_bucket_name
        object = var.source_dir != null ? google_storage_bucket_object.source[0].name : var.source_archive_object
      }
    }
  }

  service_config {
    available_memory   = var.available_memory
    available_cpu      = var.available_cpu
    timeout_seconds    = var.timeout_seconds
    max_instance_count = var.max_instance_count
    min_instance_count = var.min_instance_count

    service_account_email          = var.service_account_email
    ingress_settings               = var.ingress_settings
    all_traffic_on_latest_revision = true
    vpc_connector                  = var.vpc_connector
    vpc_connector_egress_settings  = var.vpc_connector != null ? var.vpc_connector_egress_settings : null

    environment_variables = var.environment_variables

    dynamic "secret_environment_variables" {
      for_each = var.secret_environment_variables
      content {
        key        = secret_environment_variables.value.key
        project_id = secret_environment_variables.value.project_id
        secret     = secret_environment_variables.value.secret
        version    = secret_environment_variables.value.version
      }
    }
  }

  # HTTP Trigger (default)
  dynamic "event_trigger" {
    for_each = var.trigger_type == "http" ? [] : [1]
    content {
      trigger_region = var.region
      event_type     = var.trigger_type == "pubsub" ? "google.cloud.pubsub.topic.v1.messagePublished" : var.trigger_type == "storage" ? var.event_type : var.event_type
      pubsub_topic   = var.trigger_type == "pubsub" ? var.pubsub_topic : null
      retry_policy   = "RETRY_POLICY_RETRY"

      dynamic "event_filters" {
        for_each = var.trigger_type == "storage" ? [1] : []
        content {
          attribute = "bucket"
          value     = var.storage_bucket_trigger
        }
      }
    }
  }

  depends_on = [google_storage_bucket_object.source]
}

# IAM binding for unauthenticated access (if enabled)
resource "google_cloud_run_service_iam_member" "invoker" {
  count = var.allow_unauthenticated && var.trigger_type == "http" ? 1 : 0

  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.function.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
