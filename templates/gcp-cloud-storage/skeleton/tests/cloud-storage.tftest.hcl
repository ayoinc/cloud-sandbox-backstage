# =============================================================================
# GCP Cloud Storage - Terraform Tests
# =============================================================================
# Run with: terraform test
# The provider is mocked: the tests need no Google Cloud account and create nothing.
# =============================================================================

mock_provider "google" {
  mock_data "google_storage_project_service_account" {
    defaults = {
      email_address = "service-123456789012@gs-project-accounts.iam.gserviceaccount.com"
      member        = "serviceAccount:service-123456789012@gs-project-accounts.iam.gserviceaccount.com"
    }
  }

  mock_resource "google_kms_key_ring" {
    defaults = {
      id = "projects/test-project-123/locations/europe-west1/keyRings/test-dev"
    }
  }

  mock_resource "google_kms_crypto_key" {
    defaults = {
      id = "projects/test-project-123/locations/europe-west1/keyRings/test-dev/cryptoKeys/bucket"
    }
  }
}

variables {
  name        = "test"
  environment = "dev"
  project_id  = "test-project-123"
  region      = "europe-west1"
  location    = "europe-west1"
  owner       = "group:default/platform-team"
}

run "creates_bucket" {
  command = apply

  assert {
    condition     = output.bucket_name == "test-project-123-test-dev"
    error_message = "The bucket must be named <project>-<name>-<environment>"
  }

  assert {
    condition     = output.bucket_location == "europe-west1"
    error_message = "The bucket must be in the given location"
  }

  assert {
    condition     = output.kms_key_name == null
    error_message = "Customer-managed encryption must be opt-in"
  }
}

run "private_and_recoverable_by_default" {
  command = plan

  module {
    source = "./modules/cloud-storage"
  }

  assert {
    condition     = google_storage_bucket.main.uniform_bucket_level_access && google_storage_bucket.main.public_access_prevention == "enforced"
    error_message = "The bucket must use IAM only and prevent public access"
  }

  assert {
    condition     = google_storage_bucket.main.versioning[0].enabled
    error_message = "Versioning must be on by default"
  }

  assert {
    condition     = google_storage_bucket.main.soft_delete_policy[0].retention_duration_seconds == 604800
    error_message = "Soft delete must keep objects for 7 days by default"
  }

  assert {
    condition     = !google_storage_bucket.main.force_destroy
    error_message = "A bucket with objects must not be destroyable by default"
  }

  assert {
    condition     = length(google_storage_bucket.main.lifecycle_rule) == 3
    error_message = "Only the version and multipart rules must exist without tiering"
  }

  assert {
    condition     = google_storage_bucket.main.labels["owner"] == "group_default_platform-team"
    error_message = "The owner must be turned into a valid label value"
  }

  assert {
    condition     = length(google_storage_bucket_iam_member.main) == 0
    error_message = "Nobody must get access unless listed"
  }
}

run "customer_managed_key_tiering_and_access" {
  command = apply

  module {
    source = "./modules/cloud-storage"
  }

  variables {
    location                    = "EU"
    customer_managed_encryption = true
    nearline_after_days         = 30
    coldline_after_days         = 90
    expire_after_days           = 365
    object_viewers              = ["group:readers@test.internal"]
    object_users                = ["serviceAccount:writer@test-project-123.iam.gserviceaccount.com"]
  }

  assert {
    condition     = google_kms_key_ring.bucket[0].location == "europe"
    error_message = "The key ring must be in the Cloud KMS multi-region that matches EU"
  }

  assert {
    condition     = google_kms_crypto_key.bucket[0].rotation_period == "7776000s"
    error_message = "The key must rotate every 90 days"
  }

  assert {
    condition     = google_storage_bucket.main.encryption[0].default_kms_key_name == google_kms_crypto_key.bucket[0].id
    error_message = "The bucket must be encrypted with the created key"
  }

  assert {
    condition     = google_kms_crypto_key_iam_member.storage_agent[0].role == "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    error_message = "The Cloud Storage service agent must be allowed to use the key"
  }

  assert {
    condition     = length(google_storage_bucket.main.lifecycle_rule) == 6
    error_message = "Two transitions and the expiry must be added to the lifecycle"
  }

  assert {
    condition     = google_storage_bucket_iam_member.main["roles/storage.objectUser/serviceAccount:writer@test-project-123.iam.gserviceaccount.com"].role == "roles/storage.objectUser"
    error_message = "Listed members must get their role on the bucket"
  }
}

run "existing_key_takes_precedence" {
  command = plan

  module {
    source = "./modules/cloud-storage"
  }

  variables {
    customer_managed_encryption = true
    kms_key_name                = "projects/security-project/locations/europe-west1/keyRings/shared/cryptoKeys/storage"
  }

  assert {
    condition     = length(google_kms_crypto_key.bucket) == 0
    error_message = "No key must be created when one is given"
  }

  assert {
    condition     = google_storage_bucket.main.encryption[0].default_kms_key_name == var.kms_key_name
    error_message = "The bucket must be encrypted with the given key"
  }
}

run "rejects_unsupported_soft_delete_retention" {
  command = plan

  variables {
    soft_delete_retention_days = 3
  }

  expect_failures = [var.soft_delete_retention_days]
}
