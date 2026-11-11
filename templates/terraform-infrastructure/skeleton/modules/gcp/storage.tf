locals {
  bucket_names = {
    for name in concat(var.enable_storage ? ["assets"] : [], local.data_lake ? ["raw", "curated"] : []) :
    name => "${var.name_prefix}-${name}-${local.suffix}"
  }
  replica_bucket_names = {
    for name in keys(local.bucket_names) : name => "${var.name_prefix}-${name}-dr-${local.suffix}"
    if var.enable_disaster_recovery
  }

  # Age in days at which objects move to a colder storage class. The assets
  # bucket has no age rules: cost optimization turns on Autoclass there, which
  # moves objects by how often they are read.
  storage_tiers = {
    assets = []
    raw = concat(
      [{ storage_class = "NEARLINE", age = 30 }, { storage_class = "COLDLINE", age = 90 }],
      var.enable_cost_optimization ? [{ storage_class = "ARCHIVE", age = 365 }] : [],
    )
    curated = concat(
      [{ storage_class = "NEARLINE", age = 90 }],
      var.enable_cost_optimization ? [{ storage_class = "COLDLINE", age = 180 }] : [],
    )
  }

  # Deleted objects can be restored for 7 days, or 30 with backups enabled.
  soft_delete_seconds = var.enable_backup ? 2592000 : 604800

  # Roles the Storage Transfer Service agent needs for cross-bucket
  # replication.
  replication_source_roles      = ["roles/storage.legacyBucketOwner", "roles/storage.objectViewer"]
  replication_destination_roles = ["roles/storage.legacyBucketReader", "roles/storage.objectUser"]
  replication_grants = merge(
    { for pair in setproduct(keys(local.replica_bucket_names), local.replication_source_roles) :
    "source/${pair[0]}/${pair[1]}" => { bucket = google_storage_bucket.this[pair[0]].name, role = pair[1] } },
    { for pair in setproduct(keys(local.replica_bucket_names), local.replication_destination_roles) :
    "destination/${pair[0]}/${pair[1]}" => { bucket = google_storage_bucket.replica[pair[0]].name, role = pair[1] } },
  )
}

resource "google_storage_bucket" "this" {
  for_each = local.bucket_names

  project                     = var.project_id
  name                        = each.value
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = !var.require_deletion_protection
  labels                      = merge(local.labels, { purpose = each.key })

  versioning {
    enabled = true
  }

  soft_delete_policy {
    retention_duration_seconds = local.soft_delete_seconds
  }

  dynamic "encryption" {
    for_each = var.enable_kms ? [1] : []

    content {
      default_kms_key_name = local.kms_key_id
    }
  }

  dynamic "autoclass" {
    for_each = each.key == "assets" && var.enable_cost_optimization ? [1] : []

    content {
      enabled                = true
      terminal_storage_class = "ARCHIVE"
    }
  }

  dynamic "lifecycle_rule" {
    for_each = local.storage_tiers[each.key]

    content {
      action {
        type          = "SetStorageClass"
        storage_class = lifecycle_rule.value.storage_class
      }

      condition {
        age        = lifecycle_rule.value.age
        with_state = "LIVE"
      }
    }
  }

  # Replaced and deleted versions are removed after 90 days.
  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      days_since_noncurrent_time = 90
      with_state                 = "ARCHIVED"
    }
  }

  lifecycle_rule {
    action {
      type = "AbortIncompleteMultipartUpload"
    }

    condition {
      age = 7
    }
  }

  depends_on = [time_sleep.api_propagation, time_sleep.kms_iam_propagation]
}

# -----------------------------------------------------------------------------
# Disaster recovery: a copy of every bucket in the secondary region
# -----------------------------------------------------------------------------

resource "google_storage_bucket" "replica" {
  for_each = local.replica_bucket_names

  project                     = var.project_id
  name                        = each.value
  location                    = var.secondary_region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = !var.require_deletion_protection
  labels                      = merge(local.labels, { purpose = "${each.key}-replica" })

  versioning {
    enabled = true
  }

  soft_delete_policy {
    retention_duration_seconds = local.soft_delete_seconds
  }

  dynamic "encryption" {
    for_each = var.enable_kms ? [1] : []

    content {
      default_kms_key_name = local.kms_secondary_key_id
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      days_since_noncurrent_time = 90
      with_state                 = "ARCHIVED"
    }
  }

  lifecycle_rule {
    action {
      type = "AbortIncompleteMultipartUpload"
    }

    condition {
      age = 7
    }
  }

  depends_on = [time_sleep.api_propagation, time_sleep.kms_iam_propagation]
}

data "google_storage_transfer_project_service_account" "this" {
  count = local.replication ? 1 : 0

  project = terraform_data.api_ready["storagetransfer.googleapis.com"].output
}

resource "google_storage_bucket_iam_member" "replication" {
  for_each = local.replication_grants

  bucket = each.value.bucket
  role   = each.value.role
  member = data.google_storage_transfer_project_service_account.this[0].member
}

# Replication is driven by change notifications: Cloud Storage publishes them
# and Storage Transfer Service creates and reads the subscription.
resource "google_project_iam_member" "replication_pubsub_editor" {
  count = local.replication ? 1 : 0

  project = var.project_id
  role    = "roles/pubsub.editor"
  member  = data.google_storage_transfer_project_service_account.this[0].member
}

resource "google_project_iam_member" "replication_pubsub_publisher" {
  count = local.replication ? 1 : 0

  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = local.storage_agent
}

# Copies new and changed objects to the replica bucket. Objects deleted from
# the source stay in the replica.
resource "google_storage_transfer_job" "replication" {
  for_each = local.replica_bucket_names

  project     = var.project_id
  description = "Replicates the ${each.key} bucket of ${var.name_prefix} to ${var.secondary_region}"
  status      = "ENABLED"

  replication_spec {
    gcs_data_source {
      bucket_name = google_storage_bucket.this[each.key].name
    }

    gcs_data_sink {
      bucket_name = google_storage_bucket.replica[each.key].name
    }

    transfer_options {
      overwrite_when = "DIFFERENT"
    }
  }

  depends_on = [
    google_storage_bucket_iam_member.replication,
    google_project_iam_member.replication_pubsub_editor,
    google_project_iam_member.replication_pubsub_publisher,
  ]
}
