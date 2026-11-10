# =============================================================================
# Storage: Cloud Storage buckets and Filestore
# =============================================================================

locals {
  # Buckets are encrypted with the Cloud KMS key when the security category is on.
  bucket_kms_key = var.enable_security ? google_kms_crypto_key.main[0].id : null

  create_log_bucket = var.enable_storage || var.enable_ai_ml
}

# Receives the access logs of the other buckets.
resource "google_storage_bucket" "logs" {
  # checkov:skip=CKV_GCP_62:This bucket is the access log destination; logging it to itself is not allowed
  count = local.create_log_bucket ? 1 : 0

  name                        = "${local.name_prefix}-logs-${random_id.suffix.hex}"
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = !local.is_production
  labels                      = local.labels

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  dynamic "encryption" {
    for_each = local.bucket_kms_key == null ? [] : [local.bucket_kms_key]
    content {
      default_kms_key_name = encryption.value
    }
  }

  depends_on = [google_project_service.main, google_kms_crypto_key_iam_member.storage]
}

# Cloud Storage delivers access logs as this group.
resource "google_storage_bucket_iam_member" "logs_writer" {
  count = local.create_log_bucket ? 1 : 0

  bucket = google_storage_bucket.logs[0].name
  role   = "roles/storage.objectCreator"
  member = "group:cloud-storage-analytics@google.com"
}

resource "google_storage_bucket" "data" {
  count = var.enable_storage ? 1 : 0

  name                        = "${local.name_prefix}-data-${random_id.suffix.hex}"
  location                    = var.region
  storage_class               = var.storage_class
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = !local.is_production
  labels                      = local.labels

  versioning {
    enabled = var.enable_versioning
  }

  # Previous object versions are removed after 30 days.
  lifecycle_rule {
    condition {
      days_since_noncurrent_time = 30
    }
    action {
      type = "Delete"
    }
  }

  logging {
    log_bucket        = google_storage_bucket.logs[0].name
    log_object_prefix = "data/"
  }

  dynamic "encryption" {
    for_each = local.bucket_kms_key == null ? [] : [local.bucket_kms_key]
    content {
      default_kms_key_name = encryption.value
    }
  }

  depends_on = [google_kms_crypto_key_iam_member.storage]
}

resource "google_filestore_instance" "main" {
  count = var.enable_storage && var.enable_filestore ? 1 : 0

  name     = "${local.name_prefix}-nfs"
  location = "${var.region}-a"
  tier     = "BASIC_HDD"
  labels   = local.labels

  file_shares {
    name        = "share"
    capacity_gb = var.filestore_capacity_gb
  }

  networks {
    network = local.network_name
    modes   = ["MODE_IPV4"]
  }

  depends_on = [google_project_service.main]
}
