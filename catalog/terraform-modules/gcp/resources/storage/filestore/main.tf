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
}

resource "google_filestore_instance" "this" {
  project     = var.project_id
  name        = var.name
  location    = var.zone
  description = var.description
  tier        = var.tier

  dynamic "file_shares" {
    for_each = var.file_shares
    content {
      name        = file_shares.value.name
      capacity_gb = file_shares.value.capacity_gb

      dynamic "nfs_export_options" {
        for_each = file_shares.value.nfs_export_options != null ? file_shares.value.nfs_export_options : []
        content {
          ip_ranges   = nfs_export_options.value.ip_ranges
          access_mode = nfs_export_options.value.access_mode
          squash_mode = nfs_export_options.value.squash_mode
          anon_uid    = nfs_export_options.value.anon_uid
          anon_gid    = nfs_export_options.value.anon_gid
        }
      }
    }
  }

  networks {
    network           = var.network
    modes             = ["MODE_IPV4"]
    connect_mode      = var.connect_mode
    reserved_ip_range = var.reserved_ip_range
  }

  kms_key_name = var.kms_key_name

  labels = merge(local.default_labels, var.labels)
}
