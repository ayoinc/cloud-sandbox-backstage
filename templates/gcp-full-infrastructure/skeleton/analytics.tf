# =============================================================================
# Analytics: BigQuery dataset and Pub/Sub
# =============================================================================

resource "google_bigquery_dataset" "main" {
  count = var.enable_analytics ? 1 : 0

  dataset_id                 = replace("${local.name_prefix}_analytics", "-", "_")
  description                = "Analytics dataset of ${var.project_name} (${var.environment})"
  location                   = var.region
  delete_contents_on_destroy = !local.is_production
  labels                     = local.labels

  dynamic "default_encryption_configuration" {
    for_each = var.enable_security ? [google_kms_crypto_key.main[0].id] : []
    content {
      kms_key_name = default_encryption_configuration.value
    }
  }

  depends_on = [google_project_service.main, google_kms_crypto_key_iam_member.bigquery]
}

resource "google_pubsub_topic" "events" {
  # checkov:skip=CKV_GCP_83:Google-managed encryption is used; a customer-managed key needs a grant to the Pub/Sub service agent first
  count = var.enable_analytics ? 1 : 0

  name                       = "${local.name_prefix}-events"
  message_retention_duration = "604800s"
  labels                     = local.labels

  depends_on = [google_project_service.main]
}

resource "google_pubsub_subscription" "events" {
  count = var.enable_analytics ? 1 : 0

  name                       = "${local.name_prefix}-events"
  topic                      = google_pubsub_topic.events[0].id
  ack_deadline_seconds       = 60
  message_retention_duration = "604800s"
  labels                     = local.labels

  expiration_policy {
    ttl = ""
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}
