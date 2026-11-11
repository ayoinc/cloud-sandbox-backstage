# -----------------------------------------------------------------------------
# Object storage: Cloud Storage bucket, copied daily to a bucket in the
# secondary region when set
# -----------------------------------------------------------------------------

variable "secondary_region" {
  description = "Google Cloud region that receives a daily copy of the bucket. Null disables it."
  type        = string
  default     = null
}

locals {
  storage_replication_enabled = var.secondary_region != null
}

resource "google_project_service" "storage" {
  project            = local.project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_storage_bucket" "this" {
  project  = local.project_id
  name     = module.naming.global["gcs"]
  location = var.region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = var.environment != "production"

  versioning {
    enabled = true
  }

  depends_on = [google_project_service.storage]
}

# Disaster-recovery copy in the secondary region, refreshed once a day by
# Storage Transfer Service.
resource "google_storage_bucket" "replica" {
  count = local.storage_replication_enabled ? 1 : 0

  project  = local.project_id
  name     = module.naming.global["gcsdr"]
  location = var.secondary_region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = var.environment != "production"

  versioning {
    enabled = true
  }

  depends_on = [google_project_service.storage]
}

resource "google_project_service" "storage_transfer" {
  count = local.storage_replication_enabled ? 1 : 0

  project            = local.project_id
  service            = "storagetransfer.googleapis.com"
  disable_on_destroy = false
}

data "google_storage_transfer_project_service_account" "this" {
  count = local.storage_replication_enabled ? 1 : 0

  project = local.project_id

  depends_on = [google_project_service.storage_transfer]
}

resource "google_storage_bucket_iam_member" "transfer_source" {
  for_each = local.storage_replication_enabled ? toset(["roles/storage.objectViewer", "roles/storage.legacyBucketReader"]) : []

  bucket = google_storage_bucket.this.name
  role   = each.value
  member = "serviceAccount:${data.google_storage_transfer_project_service_account.this[0].email}"
}

resource "google_storage_bucket_iam_member" "transfer_sink" {
  for_each = local.storage_replication_enabled ? toset(["roles/storage.objectAdmin", "roles/storage.legacyBucketWriter"]) : []

  bucket = google_storage_bucket.replica[0].name
  role   = each.value
  member = "serviceAccount:${data.google_storage_transfer_project_service_account.this[0].email}"
}

resource "google_storage_transfer_job" "replication" {
  count = local.storage_replication_enabled ? 1 : 0

  project     = local.project_id
  description = "Copies the ${var.component_name} bucket to ${var.secondary_region}"

  transfer_spec {
    gcs_data_source {
      bucket_name = google_storage_bucket.this.name
    }

    gcs_data_sink {
      bucket_name = google_storage_bucket.replica[0].name
    }
  }

  schedule {
    schedule_start_date {
      year  = 2025
      month = 1
      day   = 1
    }

    start_time_of_day {
      hours   = 2
      minutes = 0
      seconds = 0
      nanos   = 0
    }
  }

  depends_on = [
    google_storage_bucket_iam_member.transfer_source,
    google_storage_bucket_iam_member.transfer_sink,
  ]
}

output "storage_bucket_name" {
  description = "Name of the Cloud Storage bucket."
  value       = google_storage_bucket.this.name
}

output "storage_bucket_url" {
  description = "gs:// URL of the Cloud Storage bucket."
  value       = google_storage_bucket.this.url
}

output "storage_replica_bucket_name" {
  description = "Name of the copy bucket in the secondary region. Null without a secondary region."
  value       = one(google_storage_bucket.replica[*].name)
}
