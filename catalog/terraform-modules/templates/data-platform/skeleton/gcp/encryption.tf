# -----------------------------------------------------------------------------
# Encryption at rest. With enable_encryption, buckets, BigQuery datasets and
# Pub/Sub topics use customer-managed Cloud KMS keys, one key per service.
# Without it they use Google-managed keys.
# -----------------------------------------------------------------------------

locals {
  kms_key_names = ["storage", "bigquery", "pubsub"]
}

module "kms" {
  count  = var.enable_encryption ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/security/kms?ref=${{ values.moduleRef }}"

  project_name  = var.project_name
  project_id    = var.gcp_project_id
  environment   = var.environment
  location      = var.region
  key_ring_name = "${local.name_prefix}-data"

  crypto_keys = [
    for name in local.kms_key_names : {
      name             = name
      purpose          = "ENCRYPT_DECRYPT"
      rotation_period  = "7776000s" # 90 days
      algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
      protection_level = "SOFTWARE"
      labels           = local.labels
      version_template = {
        algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
        protection_level = "SOFTWARE"
      }
    }
  ]

  depends_on = [google_project_service.apis]
}

# The Google-managed service agents that encrypt and decrypt on behalf of each service.
data "google_storage_project_service_account" "this" {
  count = var.enable_encryption && local.needs_storage ? 1 : 0

  project = var.gcp_project_id

  depends_on = [google_project_service.apis]
}

data "google_bigquery_default_service_account" "this" {
  count = var.enable_encryption && var.enable_data_warehouse ? 1 : 0

  project = var.gcp_project_id

  depends_on = [google_project_service.apis]
}

locals {
  kms_key_ids = var.enable_encryption ? module.kms[0].crypto_key_ids : { for name in local.kms_key_names : name => null }

  # Key name => service agent that uses it. An agent gets access only when its service is in use.
  kms_service_agents = merge(
    var.enable_encryption && local.needs_storage ? { storage = data.google_storage_project_service_account.this[0].member } : {},
    var.enable_encryption && var.enable_data_warehouse ? { bigquery = data.google_bigquery_default_service_account.this[0].member } : {},
    var.enable_encryption && var.enable_streaming ? { pubsub = google_project_service_identity.pubsub[0].member } : {},
  )
}

resource "google_kms_crypto_key_iam_member" "service_agent" {
  for_each = local.kms_service_agents

  crypto_key_id = local.kms_key_ids[each.key]
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = each.value
}
