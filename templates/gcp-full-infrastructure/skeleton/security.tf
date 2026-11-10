# =============================================================================
# Security: Cloud KMS key, application service account and Secret Manager
# =============================================================================

data "google_storage_project_service_account" "main" {
  count = var.enable_security && (var.enable_storage || var.enable_ai_ml) ? 1 : 0

  project = var.project_id

  depends_on = [google_project_service.main]
}

data "google_bigquery_default_service_account" "main" {
  count = var.enable_security && var.enable_analytics ? 1 : 0

  project = var.project_id

  depends_on = [google_project_service.main]
}

resource "google_kms_key_ring" "main" {
  count = var.enable_security ? 1 : 0

  name     = "${local.name_prefix}-${random_id.suffix.hex}"
  location = var.region

  depends_on = [google_project_service.main]
}

# Encrypts the Cloud Storage buckets and the BigQuery dataset.
resource "google_kms_crypto_key" "main" {
  # checkov:skip=CKV_GCP_82:prevent_destroy cannot depend on the environment and would block removing a development stack; Cloud KMS never deletes key material immediately
  count = var.enable_security ? 1 : 0

  name            = "data"
  key_ring        = google_kms_key_ring.main[0].id
  rotation_period = "7776000s"
  labels          = local.labels
}

resource "google_kms_crypto_key_iam_member" "storage" {
  count = var.enable_security && (var.enable_storage || var.enable_ai_ml) ? 1 : 0

  crypto_key_id = google_kms_crypto_key.main[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.main[0].email_address}"
}

resource "google_kms_crypto_key_iam_member" "bigquery" {
  count = var.enable_security && var.enable_analytics ? 1 : 0

  crypto_key_id = google_kms_crypto_key.main[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_bigquery_default_service_account.main[0].email}"
}

# Identity for application workloads.
resource "google_service_account" "app" {
  count = var.enable_security ? 1 : 0

  account_id   = "${local.sa_prefix}-app"
  display_name = "Application workloads of ${local.name_prefix}"

  depends_on = [google_project_service.main]
}

# Holds the application configuration. Add versions with
# `gcloud secrets versions add`.
resource "google_secret_manager_secret" "app" {
  count = var.enable_security ? 1 : 0

  secret_id = "${local.name_prefix}-app-config"
  labels    = local.labels

  replication {
    auto {}
  }

  depends_on = [google_project_service.main]
}

resource "google_secret_manager_secret_iam_member" "app" {
  count = var.enable_security ? 1 : 0

  secret_id = google_secret_manager_secret.app[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app[0].email}"
}
