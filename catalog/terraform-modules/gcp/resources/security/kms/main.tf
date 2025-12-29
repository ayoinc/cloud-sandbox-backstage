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
  default_labels = merge(
    {
      project     = var.project_name
      environment = var.environment
      managed_by  = "terraform"
    },
    var.labels
  )

  crypto_keys_map = { for key in var.crypto_keys : key.name => key }

  iam_bindings_flat = flatten([
    for binding in var.key_iam_bindings : [
      for member in binding.members : {
        key_name = binding.key_name
        role     = binding.role
        member   = member
      }
    ]
  ])
}

resource "google_kms_key_ring" "key_ring" {
  name     = var.key_ring_name
  project  = var.project_id
  location = var.location
}

resource "google_kms_crypto_key" "crypto_keys" {
  for_each = local.crypto_keys_map

  name     = each.value.name
  key_ring = google_kms_key_ring.key_ring.id

  purpose         = each.value.purpose
  rotation_period = each.value.rotation_period

  labels = merge(local.default_labels, each.value.labels)

  version_template {
    algorithm        = each.value.algorithm
    protection_level = each.value.protection_level
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_member" "key_iam" {
  for_each = {
    for binding in local.iam_bindings_flat :
    "${binding.key_name}-${binding.role}-${binding.member}" => binding
  }

  crypto_key_id = google_kms_crypto_key.crypto_keys[each.value.key_name].id
  role          = each.value.role
  member        = each.value.member
}
