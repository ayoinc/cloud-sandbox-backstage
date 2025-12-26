# -----------------------------------------------------------------------------
# GCP Security Module - Main Resources
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "google_project" "current" {
  project_id = var.project_id
}

data "google_client_config" "current" {}

# -----------------------------------------------------------------------------
# Local Variables
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_id}-${var.environment}"

  default_labels = {
    project     = var.project_id
    environment = var.environment
    managed_by  = "terraform"
  }

  labels = merge(local.default_labels, var.labels)
}

# -----------------------------------------------------------------------------
# KMS Key Ring
# -----------------------------------------------------------------------------

resource "google_kms_key_ring" "main" {
  name     = "${local.name_prefix}-keyring"
  project  = var.project_id
  location = var.region
}

# -----------------------------------------------------------------------------
# KMS Crypto Key with Rotation Schedule
# -----------------------------------------------------------------------------

resource "google_kms_crypto_key" "main" {
  name     = "${local.name_prefix}-key"
  key_ring = google_kms_key_ring.main.id
  purpose  = "ENCRYPT_DECRYPT"

  # Rotation period (default 90 days = 7776000 seconds)
  rotation_period = var.kms_key_rotation_period

  version_template {
    algorithm        = var.kms_key_algorithm
    protection_level = var.kms_key_protection_level
  }

  labels = local.labels

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# KMS Crypto Key IAM Members
# -----------------------------------------------------------------------------

resource "google_kms_crypto_key_iam_member" "encrypter_decrypters" {
  for_each = toset(var.kms_encrypter_decrypters)

  crypto_key_id = google_kms_crypto_key.main.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = each.value
}

# Grant service account access to KMS key
resource "google_kms_crypto_key_iam_member" "service_account_access" {
  crypto_key_id = google_kms_crypto_key.main.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.application.email}"
}

# -----------------------------------------------------------------------------
# Service Account for Applications
# -----------------------------------------------------------------------------

resource "google_service_account" "application" {
  account_id   = "${local.name_prefix}-app-sa"
  display_name = "Application Service Account for ${local.name_prefix}"
  project      = var.project_id
  description  = "Managed by Terraform - Service account for application workloads"
}

# -----------------------------------------------------------------------------
# Service Account IAM Roles
# -----------------------------------------------------------------------------

resource "google_project_iam_member" "service_account_roles" {
  for_each = toset(var.service_account_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.application.email}"
}

# -----------------------------------------------------------------------------
# Secret Manager - Application Secrets
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "app_secrets" {
  secret_id = "${local.name_prefix}-app-secrets"
  project   = var.project_id

  replication {
    auto {
      customer_managed_encryption {
        kms_key_name = google_kms_crypto_key.main.id
      }
    }
  }

  labels = local.labels
}

# Secret Version with Placeholder Values
resource "google_secret_manager_secret_version" "app_secrets" {
  secret      = google_secret_manager_secret.app_secrets.id
  secret_data = jsonencode(var.secret_data)

  lifecycle {
    ignore_changes = [secret_data]
  }
}

# -----------------------------------------------------------------------------
# Secret Manager IAM - Access Control
# -----------------------------------------------------------------------------

# Grant service account access to secrets
resource "google_secret_manager_secret_iam_member" "service_account_access" {
  secret_id = google_secret_manager_secret.app_secrets.secret_id
  project   = var.project_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.application.email}"
}

# Additional secret accessors
resource "google_secret_manager_secret_iam_member" "secret_accessors" {
  for_each = toset(var.secret_accessors)

  secret_id = google_secret_manager_secret.app_secrets.secret_id
  project   = var.project_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value
}

# -----------------------------------------------------------------------------
# Additional Secrets (Dynamic)
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "additional" {
  for_each = var.additional_secrets

  secret_id = "${local.name_prefix}-${each.key}"
  project   = var.project_id

  replication {
    auto {
      customer_managed_encryption {
        kms_key_name = google_kms_crypto_key.main.id
      }
    }
  }

  labels = merge(local.labels, each.value.labels)
}

resource "google_secret_manager_secret_version" "additional" {
  for_each = var.additional_secrets

  secret      = google_secret_manager_secret.additional[each.key].id
  secret_data = each.value.secret_data

  lifecycle {
    ignore_changes = [secret_data]
  }
}

resource "google_secret_manager_secret_iam_member" "additional_accessors" {
  for_each = {
    for pair in flatten([
      for secret_key, secret in var.additional_secrets : [
        for accessor in secret.accessors : {
          key      = "${secret_key}-${accessor}"
          secret   = secret_key
          accessor = accessor
        }
      ]
    ]) : pair.key => pair
  }

  secret_id = google_secret_manager_secret.additional[each.value.secret].secret_id
  project   = var.project_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value.accessor
}

# -----------------------------------------------------------------------------
# Organization Policy (Optional)
# -----------------------------------------------------------------------------

resource "google_project_organization_policy" "domain_restricted_sharing" {
  count = var.enable_org_policies && var.allowed_policy_member_domains != null ? 1 : 0

  project    = var.project_id
  constraint = "iam.allowedPolicyMemberDomains"

  list_policy {
    allow {
      values = var.allowed_policy_member_domains
    }
  }
}

resource "google_project_organization_policy" "uniform_bucket_level_access" {
  count = var.enable_org_policies ? 1 : 0

  project    = var.project_id
  constraint = "storage.uniformBucketLevelAccess"

  boolean_policy {
    enforced = true
  }
}

resource "google_project_organization_policy" "public_access_prevention" {
  count = var.enable_org_policies ? 1 : 0

  project    = var.project_id
  constraint = "storage.publicAccessPrevention"

  boolean_policy {
    enforced = true
  }
}

resource "google_project_organization_policy" "require_os_login" {
  count = var.enable_org_policies && var.require_os_login ? 1 : 0

  project    = var.project_id
  constraint = "compute.requireOsLogin"

  boolean_policy {
    enforced = true
  }
}

resource "google_project_organization_policy" "disable_serial_port_access" {
  count = var.enable_org_policies ? 1 : 0

  project    = var.project_id
  constraint = "compute.disableSerialPortAccess"

  boolean_policy {
    enforced = true
  }
}

resource "google_project_organization_policy" "vm_external_ip" {
  count = var.enable_org_policies && var.restrict_vm_external_ips ? 1 : 0

  project    = var.project_id
  constraint = "compute.vmExternalIpAccess"

  list_policy {
    deny {
      all = true
    }
  }
}

# -----------------------------------------------------------------------------
# Cloud Audit Logs Configuration
# -----------------------------------------------------------------------------

resource "google_project_iam_audit_config" "all_services" {
  count = var.enable_audit_logs ? 1 : 0

  project = var.project_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# -----------------------------------------------------------------------------
# Service Account Key (Optional - for external systems)
# -----------------------------------------------------------------------------

resource "google_service_account_key" "application" {
  count = var.create_service_account_key ? 1 : 0

  service_account_id = google_service_account.application.name
  key_algorithm      = "KEY_ALG_RSA_2048"
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

# Store the service account key in Secret Manager (if created)
resource "google_secret_manager_secret" "service_account_key" {
  count = var.create_service_account_key ? 1 : 0

  secret_id = "${local.name_prefix}-sa-key"
  project   = var.project_id

  replication {
    auto {
      customer_managed_encryption {
        kms_key_name = google_kms_crypto_key.main.id
      }
    }
  }

  labels = local.labels
}

resource "google_secret_manager_secret_version" "service_account_key" {
  count = var.create_service_account_key ? 1 : 0

  secret      = google_secret_manager_secret.service_account_key[0].id
  secret_data = base64decode(google_service_account_key.application[0].private_key)
}
