# -----------------------------------------------------------------------------
# Cloud Storage buckets of every part of the platform, with the same protection:
# no public access, uniform bucket-level access and, with enable_encryption, the
# customer-managed key.
# -----------------------------------------------------------------------------

locals {
  # Bucket names are global. The suffix is derived from the Google Cloud project,
  # so names are stable, known when planning and do not collide across projects.
  bucket_suffix = substr(sha256(var.gcp_project_id), 0, 8)

  buckets = merge(local.lake_buckets, local.etl_buckets, local.ml_buckets)
}

resource "google_storage_bucket" "this" {
  for_each = local.buckets

  name          = "${local.name_prefix}-${each.value.name}-${local.bucket_suffix}"
  location      = var.region
  storage_class = "STANDARD"
  force_destroy = each.value.force_destroy

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = each.value.versioning
  }

  dynamic "encryption" {
    for_each = var.enable_encryption ? [1] : []

    content {
      default_kms_key_name = local.kms_key_ids["storage"]
    }
  }

  dynamic "lifecycle_rule" {
    for_each = each.value.transition_class == null ? [] : [each.value.transition_class]

    content {
      action {
        type          = "SetStorageClass"
        storage_class = lifecycle_rule.value
      }

      condition {
        age                   = var.data_lake_transition_days
        matches_storage_class = ["STANDARD"]
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = each.value.expire_after_days == null ? [] : [each.value.expire_after_days]

    content {
      action {
        type = "Delete"
      }

      condition {
        age = lifecycle_rule.value
      }
    }
  }

  # Keep the five most recent versions of an overwritten or deleted object.
  dynamic "lifecycle_rule" {
    for_each = each.value.versioning ? [1] : []

    content {
      action {
        type = "Delete"
      }

      condition {
        num_newer_versions = 5
        with_state         = "ARCHIVED"
      }
    }
  }

  labels = {
    purpose = each.key
  }

  depends_on = [google_project_service.apis, google_kms_crypto_key_iam_member.service_agent]
}

# The pipeline workers and the Workbench instance read and write their own buckets.
resource "google_storage_bucket_iam_member" "owner_workload" {
  for_each = { for key, bucket in local.buckets : key => bucket if bucket.object_role != null }

  bucket = google_storage_bucket.this[each.key].name
  role   = each.value.object_role
  member = each.value.object_role_member
}
