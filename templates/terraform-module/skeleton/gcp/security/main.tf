locals {
  # Resource names are limited to 63 characters and service account IDs to 30,
  # so the project name is shortened before the environment is appended.
  name_prefix = "${trimsuffix(substr(var.project_name, 0, 16), "-")}-${var.environment}"

  labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })

  service_account_member = "serviceAccount:${google_service_account.application.email}"

  org_policy_parent = "projects/${var.project_id}"
}

# -----------------------------------------------------------------------------
# Customer-managed encryption key
# -----------------------------------------------------------------------------

# Key rings can never be deleted, so a suffix keeps the name free for a later re-creation.
resource "random_id" "key_ring" {
  byte_length = 4
}

resource "google_kms_key_ring" "main" {
  project  = var.project_id
  name     = "${local.name_prefix}-${random_id.key_ring.hex}"
  location = var.region
}

resource "google_kms_crypto_key" "main" {
  name            = "${local.name_prefix}-key"
  key_ring        = google_kms_key_ring.main.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = var.kms_key_rotation_period
  labels          = local.labels

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = var.kms_key_protection_level
  }
}

resource "google_kms_crypto_key_iam_member" "application" {
  crypto_key_id = google_kms_crypto_key.main.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = local.service_account_member
}

resource "google_kms_crypto_key_iam_member" "encrypter_decrypters" {
  for_each = toset(var.kms_encrypter_decrypters)

  crypto_key_id = google_kms_crypto_key.main.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = each.value
}

# Cloud Storage encrypts buckets with its own service agent, which needs access to the key.
data "google_storage_project_service_account" "main" {
  count = var.grant_storage_service_agent ? 1 : 0

  project = var.project_id
}

resource "google_kms_crypto_key_iam_member" "storage_service_agent" {
  count = var.grant_storage_service_agent ? 1 : 0

  crypto_key_id = google_kms_crypto_key.main.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.main[0].email_address}"
}

# -----------------------------------------------------------------------------
# Application service account
# -----------------------------------------------------------------------------

resource "google_service_account" "application" {
  project      = var.project_id
  account_id   = "${local.name_prefix}-app"
  display_name = "${var.project_name} ${var.environment} application"
  description  = "Identity for ${var.project_name} workloads in ${var.environment}"
}

resource "google_project_iam_member" "application" {
  for_each = toset(var.service_account_roles)

  project = var.project_id
  role    = each.value
  member  = local.service_account_member
}

# -----------------------------------------------------------------------------
# Secret Manager
# -----------------------------------------------------------------------------

# Only the secret containers are managed here. Values are added as versions
# outside Terraform so they never reach the state file.
resource "google_secret_manager_secret" "main" {
  for_each = toset(var.secret_names)

  project   = var.project_id
  secret_id = "${local.name_prefix}-${each.value}"
  labels    = local.labels

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_iam_member" "application" {
  for_each = google_secret_manager_secret.main

  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = local.service_account_member
}

resource "google_secret_manager_secret_iam_member" "accessors" {
  for_each = {
    for pair in setproduct(var.secret_names, var.secret_accessors) :
    "${pair[0]}/${pair[1]}" => { secret = pair[0], member = pair[1] }
  }

  project   = var.project_id
  secret_id = google_secret_manager_secret.main[each.value.secret].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value.member
}

# -----------------------------------------------------------------------------
# Audit logging
# -----------------------------------------------------------------------------

resource "google_project_iam_audit_config" "all_services" {
  count = var.enable_audit_logs ? 1 : 0

  project = var.project_id
  service = "allServices"

  dynamic "audit_log_config" {
    for_each = ["ADMIN_READ", "DATA_READ", "DATA_WRITE"]

    content {
      log_type = audit_log_config.value
    }
  }
}

# -----------------------------------------------------------------------------
# Organization policies enforced on the project
# -----------------------------------------------------------------------------

resource "google_org_policy_policy" "require_os_login" {
  count = var.enable_org_policies && var.require_os_login ? 1 : 0

  name   = "${local.org_policy_parent}/policies/compute.requireOsLogin"
  parent = local.org_policy_parent

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "restrict_vm_external_ips" {
  count = var.enable_org_policies && var.restrict_vm_external_ips ? 1 : 0

  name   = "${local.org_policy_parent}/policies/compute.vmExternalIpAccess"
  parent = local.org_policy_parent

  spec {
    rules {
      deny_all = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "allowed_policy_member_domains" {
  count = var.enable_org_policies && length(var.allowed_policy_member_domains) > 0 ? 1 : 0

  name   = "${local.org_policy_parent}/policies/iam.allowedPolicyMemberDomains"
  parent = local.org_policy_parent

  spec {
    rules {
      values {
        allowed_values = var.allowed_policy_member_domains
      }
    }
  }
}
