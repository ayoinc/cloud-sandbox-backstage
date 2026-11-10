# =============================================================================
# AI/ML: Vertex AI service account and artifact bucket
# =============================================================================

resource "google_service_account" "vertex" {
  count = var.enable_ai_ml ? 1 : 0

  account_id   = "${local.sa_prefix}-ai"
  display_name = "Vertex AI workloads of ${local.name_prefix}"

  depends_on = [google_project_service.main]
}

resource "google_project_iam_member" "vertex" {
  count = var.enable_ai_ml ? 1 : 0

  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.vertex[0].email}"
}

# Training data, models and pipeline artifacts.
resource "google_storage_bucket" "vertex" {
  count = var.enable_ai_ml ? 1 : 0

  name                        = "${local.name_prefix}-vertex-${random_id.suffix.hex}"
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = !local.is_production
  labels                      = local.labels

  versioning {
    enabled = true
  }

  logging {
    log_bucket        = google_storage_bucket.logs[0].name
    log_object_prefix = "vertex/"
  }

  dynamic "encryption" {
    for_each = local.bucket_kms_key == null ? [] : [local.bucket_kms_key]
    content {
      default_kms_key_name = encryption.value
    }
  }

  depends_on = [google_kms_crypto_key_iam_member.storage]
}

resource "google_storage_bucket_iam_member" "vertex" {
  count = var.enable_ai_ml ? 1 : 0

  bucket = google_storage_bucket.vertex[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vertex[0].email}"
}
