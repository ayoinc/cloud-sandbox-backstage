# Terraform native tests for GCP Cloud Storage module

variables {
  project_name = "test-project"
  project_id   = "my-gcp-project"
  environment  = "test"
  location     = "US"
  bucket_name  = "test-bucket-unique-12345"

  storage_class         = "STANDARD"
  enable_versioning     = true
  uniform_bucket_access = true

  labels = {
    test = "true"
  }
}

run "bucket_creation" {
  command = plan

  assert {
    condition     = google_storage_bucket.main.location == "US"
    error_message = "Bucket location should be US"
  }

  assert {
    condition     = google_storage_bucket.main.storage_class == "STANDARD"
    error_message = "Storage class should be STANDARD"
  }
}

run "versioning_enabled" {
  command = plan

  assert {
    condition     = google_storage_bucket.main.versioning[0].enabled == true
    error_message = "Versioning should be enabled"
  }
}

run "uniform_access_enabled" {
  command = plan

  assert {
    condition     = google_storage_bucket.main.uniform_bucket_level_access == true
    error_message = "Uniform bucket-level access should be enabled"
  }
}

run "public_access_prevention" {
  command = plan

  assert {
    condition     = google_storage_bucket.main.public_access_prevention == "enforced"
    error_message = "Public access prevention should be enforced"
  }
}
