################################################################################
# GCP Cloud Storage Module
# Creates a Cloud Storage bucket with lifecycle rules, IAM, and access settings
################################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

################################################################################
# Local Variables
################################################################################

locals {
  bucket_name = var.bucket_name

  labels = merge(
    var.labels,
    {
      module = "cloud-storage"
    }
  )
}

################################################################################
# Cloud Storage Bucket
################################################################################

resource "google_storage_bucket" "this" {
  name          = local.bucket_name
  project       = var.project_id
  location      = var.location
  storage_class = var.storage_class
  force_destroy = var.force_destroy

  # Uniform bucket-level access
  uniform_bucket_level_access = var.uniform_bucket_level_access

  # Public access prevention
  public_access_prevention = var.public_access_prevention

  # Versioning
  versioning {
    enabled = var.versioning_enabled
  }

  # Encryption
  dynamic "encryption" {
    for_each = var.kms_key_name != null ? [1] : []
    content {
      default_kms_key_name = var.kms_key_name
    }
  }

  # Lifecycle rules
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }
      condition {
        age                        = lookup(lifecycle_rule.value.condition, "age", null)
        created_before             = lookup(lifecycle_rule.value.condition, "created_before", null)
        with_state                 = lookup(lifecycle_rule.value.condition, "with_state", null)
        matches_storage_class      = lookup(lifecycle_rule.value.condition, "matches_storage_class", null)
        matches_prefix             = lookup(lifecycle_rule.value.condition, "matches_prefix", null)
        matches_suffix             = lookup(lifecycle_rule.value.condition, "matches_suffix", null)
        num_newer_versions         = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
        days_since_noncurrent_time = lookup(lifecycle_rule.value.condition, "days_since_noncurrent_time", null)
        noncurrent_time_before     = lookup(lifecycle_rule.value.condition, "noncurrent_time_before", null)
      }
    }
  }

  # CORS configuration
  dynamic "cors" {
    for_each = var.cors_configurations
    content {
      origin          = cors.value.origins
      method          = cors.value.methods
      response_header = lookup(cors.value, "response_headers", [])
      max_age_seconds = lookup(cors.value, "max_age_seconds", 3600)
    }
  }

  # Website configuration
  dynamic "website" {
    for_each = var.website_config != null ? [var.website_config] : []
    content {
      main_page_suffix = lookup(website.value, "main_page_suffix", "index.html")
      not_found_page   = lookup(website.value, "not_found_page", "404.html")
    }
  }

  # Retention policy
  dynamic "retention_policy" {
    for_each = var.retention_policy != null ? [var.retention_policy] : []
    content {
      is_locked        = lookup(retention_policy.value, "is_locked", false)
      retention_period = retention_policy.value.retention_period
    }
  }

  # Logging
  dynamic "logging" {
    for_each = var.logging_config != null ? [var.logging_config] : []
    content {
      log_bucket        = logging.value.log_bucket
      log_object_prefix = lookup(logging.value, "log_object_prefix", null)
    }
  }

  # Autoclass
  dynamic "autoclass" {
    for_each = var.autoclass_enabled ? [1] : []
    content {
      enabled = true
    }
  }

  labels = local.labels
}

################################################################################
# IAM Bindings
################################################################################

resource "google_storage_bucket_iam_binding" "bindings" {
  for_each = var.iam_bindings

  bucket  = google_storage_bucket.this.name
  role    = each.value.role
  members = each.value.members

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = lookup(condition.value, "description", null)
      expression  = condition.value.expression
    }
  }
}

################################################################################
# Object ACLs (for non-uniform access buckets)
################################################################################

resource "google_storage_default_object_access_control" "default_acl" {
  for_each = var.uniform_bucket_level_access ? {} : var.default_object_acls

  bucket = google_storage_bucket.this.name
  role   = each.value.role
  entity = each.value.entity
}

################################################################################
# Bucket Notification
################################################################################

resource "google_storage_notification" "notifications" {
  for_each = var.notifications

  bucket         = google_storage_bucket.this.name
  topic          = each.value.topic
  payload_format = lookup(each.value, "payload_format", "JSON_API_V1")
  event_types    = lookup(each.value, "event_types", ["OBJECT_FINALIZE"])

  custom_attributes = lookup(each.value, "custom_attributes", {})

  dynamic "object_name_prefix" {
    for_each = lookup(each.value, "object_name_prefix", null) != null ? [1] : []
    content {
    }
  }

  depends_on = [google_pubsub_topic_iam_binding.notification_binding]
}

# Grant GCS service account permission to publish to Pub/Sub
data "google_storage_project_service_account" "gcs_account" {
  count   = length(var.notifications) > 0 ? 1 : 0
  project = var.project_id
}

resource "google_pubsub_topic_iam_binding" "notification_binding" {
  for_each = var.notifications

  topic   = each.value.topic
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account[0].email_address}"]
}
