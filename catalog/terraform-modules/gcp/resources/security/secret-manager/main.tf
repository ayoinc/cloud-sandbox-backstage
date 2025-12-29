terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

locals {
  default_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }

  iam_bindings_flat = flatten([
    for secret in var.secrets : [
      for binding in secret.iam_bindings : {
        secret_id = secret.secret_id
        role      = binding.role
        member    = binding.member
      }
    ]
  ])
}

resource "google_secret_manager_secret" "secrets" {
  for_each = { for secret in var.secrets : secret.secret_id => secret }

  project   = var.project_id
  secret_id = each.value.secret_id

  labels = merge(local.default_labels, var.labels)

  dynamic "replication" {
    for_each = each.value.replication_type == "automatic" ? [1] : []

    content {
      auto {
        dynamic "customer_managed_encryption" {
          for_each = each.value.kms_key_name != null ? [1] : []

          content {
            kms_key_name = each.value.kms_key_name
          }
        }
      }
    }
  }

  dynamic "replication" {
    for_each = each.value.replication_type == "user_managed" ? [1] : []

    content {
      user_managed {
        dynamic "replicas" {
          for_each = each.value.replication_locations

          content {
            location = replicas.value

            dynamic "customer_managed_encryption" {
              for_each = each.value.kms_key_name != null ? [1] : []

              content {
                kms_key_name = each.value.kms_key_name
              }
            }
          }
        }
      }
    }
  }
}

resource "google_secret_manager_secret_version" "versions" {
  for_each = { for secret in var.secrets : secret.secret_id => secret if secret.secret_data != null }

  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value.secret_data
}

resource "google_secret_manager_secret_iam_member" "members" {
  for_each = {
    for binding in local.iam_bindings_flat :
    "${binding.secret_id}-${binding.role}-${binding.member}" => binding
  }

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.value.secret_id].secret_id
  role      = each.value.role
  member    = each.value.member
}
