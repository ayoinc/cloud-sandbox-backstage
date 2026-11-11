locals {
  # Resource names are limited to 63 characters and service account IDs to 30,
  # so the project name is shortened before the environment is appended.
  name_prefix = "${trimsuffix(substr(var.project_name, 0, 16), "-")}-${var.environment}"

  labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })

  bucket_members = merge(
    { for m in var.bucket_viewers : "roles/storage.objectViewer/${m}" => { role = "roles/storage.objectViewer", member = m } },
    { for m in var.bucket_creators : "roles/storage.objectCreator/${m}" => { role = "roles/storage.objectCreator", member = m } },
    { for m in var.bucket_writers : "roles/storage.objectUser/${m}" => { role = "roles/storage.objectUser", member = m } },
  )
}

# Bucket names are global, so a random suffix keeps them unique.
resource "random_id" "bucket" {
  byte_length = 4
}

# -----------------------------------------------------------------------------
# Customer-managed encryption
# -----------------------------------------------------------------------------

data "google_storage_project_service_account" "main" {
  count = var.grant_kms_access ? 1 : 0

  project = var.project_id
}

resource "google_kms_crypto_key_iam_member" "storage_service_agent" {
  count = var.grant_kms_access ? 1 : 0

  crypto_key_id = var.kms_key_id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.main[0].email_address}"

  lifecycle {
    precondition {
      condition     = var.kms_key_id != null
      error_message = "grant_kms_access requires kms_key_id."
    }
  }
}

# -----------------------------------------------------------------------------
# Bucket
# -----------------------------------------------------------------------------

resource "google_storage_bucket" "main" {
  project       = var.project_id
  name          = "${local.name_prefix}-${var.bucket_suffix}-${random_id.bucket.hex}"
  location      = var.region
  storage_class = var.storage_class
  force_destroy = var.force_destroy
  labels        = local.labels

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = var.enable_versioning
  }

  soft_delete_policy {
    retention_duration_seconds = var.soft_delete_retention_days * 86400
  }

  dynamic "encryption" {
    for_each = var.kms_key_id == null ? [] : [var.kms_key_id]

    content {
      default_kms_key_name = encryption.value
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules

    content {
      action {
        type          = lifecycle_rule.value.action
        storage_class = lifecycle_rule.value.storage_class
      }

      condition {
        age                        = lifecycle_rule.value.age_days
        num_newer_versions         = lifecycle_rule.value.num_newer_versions
        days_since_noncurrent_time = lifecycle_rule.value.days_since_noncurrent
        with_state                 = lifecycle_rule.value.with_state
        matches_prefix             = lifecycle_rule.value.matches_prefix
      }
    }
  }

  dynamic "cors" {
    for_each = var.cors_config == null ? [] : [var.cors_config]

    content {
      origin          = cors.value.origins
      method          = cors.value.methods
      response_header = cors.value.response_headers
      max_age_seconds = cors.value.max_age_seconds
    }
  }

  dynamic "logging" {
    for_each = var.logging_bucket == null ? [] : [var.logging_bucket]

    content {
      log_bucket        = logging.value
      log_object_prefix = "${local.name_prefix}-${var.bucket_suffix}/"
    }
  }

  dynamic "retention_policy" {
    for_each = var.retention_period_seconds == null ? [] : [var.retention_period_seconds]

    content {
      retention_period = tostring(retention_policy.value)
      is_locked        = var.retention_policy_is_locked
    }
  }

  depends_on = [google_kms_crypto_key_iam_member.storage_service_agent]
}

resource "google_storage_bucket_iam_member" "main" {
  for_each = local.bucket_members

  bucket = google_storage_bucket.main.name
  role   = each.value.role
  member = each.value.member
}

# -----------------------------------------------------------------------------
# Filestore (NFS)
# -----------------------------------------------------------------------------

resource "google_filestore_instance" "main" {
  count = var.enable_filestore ? 1 : 0

  project     = var.project_id
  name        = "${local.name_prefix}-nfs"
  description = "NFS share for ${var.project_name} (${var.environment})"
  location    = coalesce(var.filestore_zone, "${var.region}-a")
  tier        = var.filestore_tier
  labels      = local.labels

  file_shares {
    name        = var.filestore_share_name
    capacity_gb = var.filestore_capacity_gb

    dynamic "nfs_export_options" {
      for_each = var.filestore_allowed_ip_ranges == null ? [] : [var.filestore_allowed_ip_ranges]

      content {
        ip_ranges   = nfs_export_options.value
        access_mode = "READ_WRITE"
        squash_mode = "ROOT_SQUASH"
      }
    }
  }

  networks {
    network = coalesce(var.filestore_network, "default")
    modes   = ["MODE_IPV4"]
  }
}
