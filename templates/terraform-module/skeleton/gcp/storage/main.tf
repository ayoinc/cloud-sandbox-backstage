# -----------------------------------------------------------------------------
# GCP Storage Module - Main Resources
# -----------------------------------------------------------------------------

# Random ID for unique bucket naming
resource "random_id" "bucket" {
  byte_length = 4
}

# -----------------------------------------------------------------------------
# Cloud Storage Bucket
# -----------------------------------------------------------------------------

resource "google_storage_bucket" "main" {
  name          = "${var.project_id}-${var.environment}-${var.bucket_suffix}-${random_id.bucket.hex}"
  project       = var.project_id
  location      = var.region
  storage_class = var.storage_class
  force_destroy = var.force_destroy

  # Uniform bucket-level access (recommended for security)
  uniform_bucket_level_access = true

  # Versioning configuration
  versioning {
    enabled = var.enable_versioning
  }

  # Lifecycle rules
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action_type
        storage_class = lifecycle_rule.value.action_storage_class
      }
      condition {
        age                        = lifecycle_rule.value.condition_age_days
        created_before             = lifecycle_rule.value.condition_created_before
        with_state                 = lifecycle_rule.value.condition_with_state
        matches_storage_class      = lifecycle_rule.value.condition_matches_storage_class
        num_newer_versions         = lifecycle_rule.value.condition_num_newer_versions
        days_since_noncurrent_time = lifecycle_rule.value.condition_days_since_noncurrent_time
      }
    }
  }

  # Encryption with customer-managed KMS key (optional)
  dynamic "encryption" {
    for_each = var.kms_key_name != null ? [1] : []
    content {
      default_kms_key_name = var.kms_key_name
    }
  }

  # CORS configuration (optional)
  dynamic "cors" {
    for_each = var.cors_config != null ? [var.cors_config] : []
    content {
      origin          = cors.value.origins
      method          = cors.value.methods
      response_header = cors.value.response_headers
      max_age_seconds = cors.value.max_age_seconds
    }
  }

  # Logging configuration (optional)
  dynamic "logging" {
    for_each = var.logging_bucket != null ? [1] : []
    content {
      log_bucket        = var.logging_bucket
      log_object_prefix = var.logging_prefix != null ? var.logging_prefix : "${var.project_id}-${var.environment}/"
    }
  }

  # Retention policy (optional)
  dynamic "retention_policy" {
    for_each = var.retention_period_seconds != null ? [1] : []
    content {
      is_locked        = var.retention_policy_is_locked
      retention_period = var.retention_period_seconds
    }
  }

  labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })
}

# -----------------------------------------------------------------------------
# Bucket IAM Members
# -----------------------------------------------------------------------------

resource "google_storage_bucket_iam_member" "viewers" {
  for_each = toset(var.bucket_viewers)

  bucket = google_storage_bucket.main.name
  role   = "roles/storage.objectViewer"
  member = each.value
}

resource "google_storage_bucket_iam_member" "admins" {
  for_each = toset(var.bucket_admins)

  bucket = google_storage_bucket.main.name
  role   = "roles/storage.objectAdmin"
  member = each.value
}

resource "google_storage_bucket_iam_member" "creators" {
  for_each = toset(var.bucket_creators)

  bucket = google_storage_bucket.main.name
  role   = "roles/storage.objectCreator"
  member = each.value
}

resource "google_storage_bucket_iam_member" "custom" {
  for_each = { for binding in var.custom_iam_bindings : "${binding.role}-${binding.member}" => binding }

  bucket = google_storage_bucket.main.name
  role   = each.value.role
  member = each.value.member
}

# -----------------------------------------------------------------------------
# Filestore Instance (Optional - NFS Storage)
# -----------------------------------------------------------------------------

resource "google_filestore_instance" "main" {
  count = var.enable_filestore ? 1 : 0

  name     = "${var.project_id}-${var.environment}-filestore"
  project  = var.project_id
  location = var.filestore_zone != null ? var.filestore_zone : "${var.region}-a"
  tier     = var.filestore_tier

  file_shares {
    name        = var.filestore_share_name
    capacity_gb = var.filestore_capacity_gb

    # NFS export options (optional)
    dynamic "nfs_export_options" {
      for_each = var.filestore_nfs_export_options
      content {
        ip_ranges   = nfs_export_options.value.ip_ranges
        access_mode = nfs_export_options.value.access_mode
        squash_mode = nfs_export_options.value.squash_mode
      }
    }
  }

  networks {
    network           = var.filestore_network
    modes             = ["MODE_IPV4"]
    reserved_ip_range = var.filestore_reserved_ip_range
  }

  labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })
}
