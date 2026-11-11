# =============================================================================
# GCP Cloud Storage Module
# =============================================================================
# Creates a Cloud Storage bucket that cannot be made public:
# - Bucket with uniform bucket-level access and public access prevention
# - Object versioning, soft delete and lifecycle rules
# - Optional Cloud KMS key ring and key (CMEK) with rotation
# - IAM bindings for the members you list
# =============================================================================

locals {
  # Bucket names are unique across Google Cloud; the project ID makes this one so.
  bucket_name = "${var.project_id}-${var.name}-${var.environment}"

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
  # Cloud KMS names its multi-regions us, europe and asia.
  kms_location = lookup({ us = "us", eu = "europe", asia = "asia" }, lower(var.location), lower(var.location))
  create_key   = var.customer_managed_encryption && var.kms_key_name == null
  kms_key_name = local.create_key ? google_kms_crypto_key.bucket[0].id : var.kms_key_name

  storage_class_transitions = {
    for class, age in {
      NEARLINE = var.nearline_after_days
      COLDLINE = var.coldline_after_days
      ARCHIVE  = var.archive_after_days
    } : class => age if age != null
  }

  apis = var.enable_apis ? toset(concat(["storage.googleapis.com"], local.kms_key_name_set ? ["cloudkms.googleapis.com"] : [])) : toset([])

  kms_key_name_set = var.customer_managed_encryption || var.kms_key_name != null

  iam_members = merge(
    { for member in var.object_viewers : "roles/storage.objectViewer/${member}" => { role = "roles/storage.objectViewer", member = member } },
    { for member in var.object_users : "roles/storage.objectUser/${member}" => { role = "roles/storage.objectUser", member = member } },
    { for member in var.object_admins : "roles/storage.objectAdmin/${member}" => { role = "roles/storage.objectAdmin", member = member } },
  )
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
# Customer-Managed Encryption Key
# =============================================================================
# Cloud Storage encrypts and decrypts with its own service agent, which needs
# the key before the bucket can use it.
data "google_storage_project_service_account" "main" {
  project = var.project_id

  depends_on = [google_project_service.main]
}

resource "google_kms_key_ring" "bucket" {
  count = local.create_key ? 1 : 0

  project  = var.project_id
  name     = "${var.name}-${var.environment}"
  location = local.kms_location

  depends_on = [google_project_service.main]
}

resource "google_kms_crypto_key" "bucket" {
  #checkov:skip=CKV_GCP_82:prevent_destroy would block the destroy action of the pipeline; destroyed key versions stay recoverable for 30 days
  count = local.create_key ? 1 : 0

  name                       = "bucket"
  key_ring                   = google_kms_key_ring.bucket[0].id
  purpose                    = "ENCRYPT_DECRYPT"
  rotation_period            = var.kms_key_rotation_period
  destroy_scheduled_duration = "2592000s"
  labels                     = local.common_labels
}

resource "google_kms_crypto_key_iam_member" "storage_agent" {
  count = local.kms_key_name_set ? 1 : 0

  crypto_key_id = local.kms_key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = data.google_storage_project_service_account.main.member
}

# =============================================================================
# Bucket
# =============================================================================
resource "google_storage_bucket" "main" {
  #checkov:skip=CKV_GCP_62:Usage logs need a second bucket; access is audited with Cloud Audit Logs data access logs instead (see the documentation)
  project       = var.project_id
  name          = local.bucket_name
  location      = var.location
  storage_class = var.storage_class
  force_destroy = var.force_destroy
  labels        = local.common_labels

  # IAM only, no object ACLs, and never allUsers or allAuthenticatedUsers.
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = var.versioning_enabled
  }

  soft_delete_policy {
    retention_duration_seconds = var.soft_delete_retention_days * 86400
  }

  dynamic "encryption" {
    for_each = local.kms_key_name_set ? [local.kms_key_name] : []

    content {
      default_kms_key_name = encryption.value
    }
  }

  dynamic "lifecycle_rule" {
    for_each = local.storage_class_transitions

    content {
      action {
        type          = "SetStorageClass"
        storage_class = lifecycle_rule.key
      }

      condition {
        age        = lifecycle_rule.value
        with_state = "LIVE"
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.expire_after_days == null ? [] : [var.expire_after_days]

    content {
      action {
        type = "Delete"
      }

      condition {
        age        = lifecycle_rule.value
        with_state = "LIVE"
      }
    }
  }

  # Previous versions: keep a few recent ones, and none for longer than the
  # retention.
  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      num_newer_versions = var.noncurrent_versions_to_keep
      with_state         = "ARCHIVED"
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      days_since_noncurrent_time = var.noncurrent_version_retention_days
      with_state                 = "ARCHIVED"
    }
  }

  lifecycle_rule {
    action {
      type = "AbortIncompleteMultipartUpload"
    }

    condition {
      age = 7
    }
  }

  depends_on = [
    google_project_service.main,
    google_kms_crypto_key_iam_member.storage_agent,
  ]

  lifecycle {
    precondition {
      condition     = length(local.bucket_name) <= 63
      error_message = "The bucket name ${local.bucket_name} must have at most 63 characters: shorten the name."
    }
  }
}

# =============================================================================
# Access
# =============================================================================
resource "google_storage_bucket_iam_member" "main" {
  for_each = local.iam_members

  bucket = google_storage_bucket.main.name
  role   = each.value.role
  member = each.value.member
}
