# =============================================================================
# GCP Cloud Run Functions Module
# =============================================================================
# Creates a Cloud Run function (Cloud Functions 2nd gen) from the source in
# this repository:
# - Dedicated runtime service account with no roles, and a build service account
# - Private, versioned bucket holding the zipped source
# - Function with an HTTP or a Pub/Sub trigger
# - IAM bindings for the callers you list, and Secret Manager access
# =============================================================================

locals {
  function_name = "${var.name}-${var.environment}"

  # Label values allow only lowercase letters, digits, underscores and hyphens.
  common_labels = merge(
    var.labels,
    {
      project     = var.name
      environment = var.environment
      managed-by  = "terraform"
    },
    var.owner != "" ? { owner = substr(replace(lower(var.owner), "/[^a-z0-9_-]/", "_"), 0, 63) } : {},
  )
  is_pubsub        = var.trigger_type == "pubsub"
  ingress_settings = coalesce(var.ingress_settings, local.is_pubsub ? "ALLOW_INTERNAL_ONLY" : "ALLOW_ALL")

  apis = var.enable_apis ? toset(concat(
    [
      "artifactregistry.googleapis.com",
      "cloudbuild.googleapis.com",
      "cloudfunctions.googleapis.com",
      "iam.googleapis.com",
      "run.googleapis.com",
      "storage.googleapis.com",
    ],
    local.is_pubsub ? ["eventarc.googleapis.com", "pubsub.googleapis.com"] : [],
    length(var.secret_environment_variables) > 0 ? ["secretmanager.googleapis.com"] : [],
  )) : toset([])

  invokers = var.trigger_type == "http" ? setunion(var.invokers, var.allow_unauthenticated ? ["allUsers"] : []) : toset([])
}

# =============================================================================
# APIs
# =============================================================================
resource "google_project_service" "main" {
  for_each = local.apis

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# =============================================================================
# Service Accounts
# =============================================================================
# The function runs as its own service account, which starts with no roles:
# grant it exactly what the code needs with runtime_service_account_roles.
resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = "run-${local.function_name}"
  display_name = "Runtime of the function ${local.function_name}"

  depends_on = [google_project_service.main]
}

resource "google_project_iam_member" "runtime" {
  for_each = var.runtime_service_account_roles

  project = var.project_id
  role    = each.value
  member  = google_service_account.runtime.member
}

resource "google_secret_manager_secret_iam_member" "runtime" {
  for_each = var.secret_environment_variables

  project   = var.project_id
  secret_id = each.value.secret
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.runtime.member
}

# Cloud Build turns the source into a container image as this account, not
# as the broadly privileged default compute service account.
resource "google_service_account" "build" {
  project      = var.project_id
  account_id   = "bld-${local.function_name}"
  display_name = "Build of the function ${local.function_name}"

  depends_on = [google_project_service.main]
}

resource "google_project_iam_member" "build" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = google_service_account.build.member
}

# =============================================================================
# Source
# =============================================================================
data "archive_file" "source" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.root}/build/function.zip"
  excludes    = ["node_modules/**", "test/**"]
}

resource "google_storage_bucket" "source" {
  #checkov:skip=CKV_GCP_62:The bucket holds only the function source, which is already versioned in this repository
  project  = var.project_id
  name     = "${var.project_id}-${local.function_name}-src"
  location = var.region
  labels   = local.common_labels

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      days_since_noncurrent_time = 30
      with_state                 = "ARCHIVED"
    }
  }

  depends_on = [google_project_service.main]
}

# The object name carries the hash of the source, so a change of the code
# creates a new object and with it a new build.
resource "google_storage_bucket_object" "source" {
  bucket = google_storage_bucket.source.name
  name   = "function-${data.archive_file.source.output_md5}.zip"
  source = data.archive_file.source.output_path
}

# =============================================================================
# Pub/Sub Trigger
# =============================================================================
resource "google_pubsub_topic" "trigger" {
  #checkov:skip=CKV_GCP_83:Messages are encrypted with Google-managed keys; set kms_key_name on the topic to use your own key
  count = local.is_pubsub ? 1 : 0

  project = var.project_id
  name    = local.function_name
  labels  = local.common_labels

  message_storage_policy {
    allowed_persistence_regions = [var.region]
  }

  depends_on = [google_project_service.main]
}

# Eventarc delivers messages to the function as this account, the only
# identity allowed to invoke it.
resource "google_service_account" "trigger" {
  count = local.is_pubsub ? 1 : 0

  project      = var.project_id
  account_id   = "trg-${local.function_name}"
  display_name = "Trigger of the function ${local.function_name}"

  depends_on = [google_project_service.main]
}

resource "google_cloud_run_service_iam_member" "trigger" {
  count = local.is_pubsub ? 1 : 0

  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.main.name
  role     = "roles/run.invoker"
  member   = google_service_account.trigger[0].member
}

# =============================================================================
# Function
# =============================================================================
resource "google_cloudfunctions2_function" "main" {
  project     = var.project_id
  name        = local.function_name
  location    = var.region
  description = substr(var.description, 0, 1024)
  labels      = local.common_labels

  build_config {
    runtime         = var.runtime
    entry_point     = var.entry_point
    service_account = google_service_account.build.id

    source {
      storage_source {
        bucket = google_storage_bucket.source.name
        object = google_storage_bucket_object.source.name
      }
    }
  }

  service_config {
    service_account_email          = google_service_account.runtime.email
    available_memory               = var.available_memory
    timeout_seconds                = var.timeout_seconds
    min_instance_count             = var.min_instance_count
    max_instance_count             = var.max_instance_count
    ingress_settings               = local.ingress_settings
    all_traffic_on_latest_revision = true
    environment_variables          = var.environment_variables

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

  dynamic "event_trigger" {
    for_each = google_pubsub_topic.trigger

    content {
      trigger_region        = var.region
      event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
      pubsub_topic          = event_trigger.value.id
      retry_policy          = "RETRY_POLICY_RETRY"
      service_account_email = google_service_account.trigger[0].email
    }
  }

  depends_on = [
    google_project_service.main,
    google_project_iam_member.build,
    google_secret_manager_secret_iam_member.runtime,
  ]

}

# =============================================================================
# Invokers
# =============================================================================
# A 2nd gen function is served by a Cloud Run service of the same name, and
# invoking it is a Cloud Run permission.
resource "google_cloud_run_service_iam_member" "invoker" {
  for_each = local.invokers

  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.main.name
  role     = "roles/run.invoker"
  member   = each.value
}
