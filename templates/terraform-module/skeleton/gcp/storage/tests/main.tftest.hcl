mock_provider "google" {}
mock_provider "random" {}

variables {
  project_name = "acme-platform"
  environment  = "dev"
  project_id   = "acme-platform-dev"
  region       = "us-central1"
}

run "defaults" {
  command = plan

  assert {
    condition     = google_storage_bucket.main.location == "us-central1"
    error_message = "The bucket must be created in the configured region."
  }

  assert {
    condition     = google_storage_bucket.main.uniform_bucket_level_access == true && google_storage_bucket.main.public_access_prevention == "enforced"
    error_message = "The bucket must use uniform access and block public access."
  }

  assert {
    condition     = google_storage_bucket.main.versioning[0].enabled == true
    error_message = "Versioning must be on by default."
  }

  assert {
    condition     = google_storage_bucket.main.soft_delete_policy[0].retention_duration_seconds == 604800
    error_message = "Soft delete must keep objects for 7 days by default."
  }

  assert {
    condition     = length(google_storage_bucket.main.encryption) == 0
    error_message = "Without a key the bucket must use Google-managed encryption."
  }

  assert {
    condition     = length(google_storage_bucket.main.lifecycle_rule) == 1
    error_message = "The default lifecycle rule must be present."
  }

  assert {
    condition     = length(google_storage_bucket_iam_member.main) == 0 && length(google_filestore_instance.main) == 0
    error_message = "No IAM members or Filestore instance may be created by default."
  }

  assert {
    condition     = output.filestore_mount_path == null
    error_message = "Filestore outputs must be null when disabled."
  }
}

run "null_optional_inputs" {
  command = plan

  variables {
    kms_key_id                  = null
    cors_config                 = null
    logging_bucket              = null
    retention_period_seconds    = null
    filestore_zone              = null
    filestore_network           = null
    filestore_allowed_ip_ranges = null
    enable_filestore            = true
  }

  assert {
    condition     = google_filestore_instance.main[0].location == "us-central1-a"
    error_message = "A null zone must fall back to zone a of the region."
  }

  assert {
    condition     = google_filestore_instance.main[0].networks[0].network == "default"
    error_message = "A null network must fall back to the default network."
  }
}

run "all_features" {
  command = plan

  variables {
    kms_key_id       = "projects/acme-platform-dev/locations/us-central1/keyRings/acme/cryptoKeys/acme-key"
    grant_kms_access = true
    bucket_suffix    = "assets"
    storage_class    = "NEARLINE"
    lifecycle_rules = [
      { action = "SetStorageClass", storage_class = "COLDLINE", age_days = 30 },
      { action = "Delete", age_days = 365 },
    ]
    cors_config = {
      origins = ["https://app.acme.example"]
      methods = ["GET"]
    }
    logging_bucket              = "acme-access-logs"
    retention_period_seconds    = 86400
    bucket_viewers              = ["group:analysts@acme.example"]
    bucket_creators             = ["serviceAccount:uploader@acme-platform-dev.iam.gserviceaccount.com"]
    bucket_writers              = ["serviceAccount:app@acme-platform-dev.iam.gserviceaccount.com"]
    enable_filestore            = true
    filestore_zone              = "us-central1-b"
    filestore_network           = "acme-platform-dev-vpc"
    filestore_allowed_ip_ranges = ["10.2.0.0/20"]
  }

  assert {
    condition     = google_storage_bucket.main.encryption[0].default_kms_key_name == "projects/acme-platform-dev/locations/us-central1/keyRings/acme/cryptoKeys/acme-key"
    error_message = "The bucket must be encrypted with the given key."
  }

  assert {
    condition     = length(google_kms_crypto_key_iam_member.storage_service_agent) == 1
    error_message = "grant_kms_access must grant the storage service agent access to the key."
  }

  assert {
    condition     = google_storage_bucket.main.storage_class == "NEARLINE" && length(google_storage_bucket.main.lifecycle_rule) == 2
    error_message = "Storage class and lifecycle rules must follow the inputs."
  }

  assert {
    condition     = google_storage_bucket.main.cors[0].max_age_seconds == 3600
    error_message = "CORS must apply the default max age."
  }

  assert {
    condition     = google_storage_bucket.main.logging[0].log_bucket == "acme-access-logs"
    error_message = "Access logs must go to the configured bucket."
  }

  assert {
    condition     = google_storage_bucket.main.retention_policy[0].retention_period == "86400"
    error_message = "The retention policy must use the configured period."
  }

  assert {
    condition     = length(google_storage_bucket_iam_member.main) == 3
    error_message = "One IAM member must be created per viewer, creator and writer."
  }

  assert {
    condition     = google_filestore_instance.main[0].name == "acme-platform-dev-nfs" && google_filestore_instance.main[0].location == "us-central1-b"
    error_message = "The Filestore instance must use the configured name and zone."
  }

  assert {
    condition     = google_filestore_instance.main[0].file_shares[0].nfs_export_options[0].squash_mode == "ROOT_SQUASH"
    error_message = "Restricted exports must squash root."
  }
}

run "rejects_kms_grant_without_key" {
  command = plan

  variables {
    grant_kms_access = true
  }

  expect_failures = [google_kms_crypto_key_iam_member.storage_service_agent]
}

run "rejects_public_members" {
  command = plan

  variables {
    bucket_viewers = ["allUsers"]
  }

  expect_failures = [var.bucket_viewers]
}

run "rejects_set_storage_class_without_class" {
  command = plan

  variables {
    lifecycle_rules = [{ action = "SetStorageClass", age_days = 30 }]
  }

  expect_failures = [var.lifecycle_rules]
}
