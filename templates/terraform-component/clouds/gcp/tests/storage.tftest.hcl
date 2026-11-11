# Plan-only tests against mocked providers: no credentials, no resources.

mock_provider "google" {
  mock_data "google_project" {
    defaults = {
      project_id = "existing-project"
      number     = "123456789012"
    }
  }
}

mock_provider "random" {
  mock_resource "random_id" {
    defaults = {
      hex = "ab12cd34"
    }
  }
}

# Every variable is set here so that the tests do not depend on terraform.tfvars.
variables {
  component_name            = "test-component"
  component_type            = "application"
  project_name              = "billing"
  environment               = "development"
  business_unit             = "engineering"
  cost_center               = "application-development"
  application_id            = ""
  owner                     = "group:default/platform-team"
  company                   = "example-org"
  naming_convention         = "enterprise"
  region                    = "us-central1"
  secondary_region          = null
  create_resource_container = true
  project_id                = ""
  billing_account           = "000000-AAAAAA-000000"
  folder_id                 = "folders/123456789"
}

run "bucket_is_private_and_versioned" {
  command = plan

  assert {
    condition     = google_storage_bucket.this.uniform_bucket_level_access && google_storage_bucket.this.public_access_prevention == "enforced"
    error_message = "The bucket must not be public."
  }

  assert {
    condition     = google_storage_bucket.this.versioning[0].enabled
    error_message = "The bucket must be versioned."
  }

  assert {
    condition     = length(google_storage_bucket.replica) == 0 && length(google_storage_transfer_job.replication) == 0
    error_message = "No copy without a secondary region."
  }
}

run "secondary_region_adds_a_copy" {
  command = plan

  variables {
    secondary_region = "us-east1"
  }

  assert {
    condition     = google_storage_bucket.replica[0].location == "US-EAST1" || lower(google_storage_bucket.replica[0].location) == "us-east1"
    error_message = "The copy bucket is created in the secondary region."
  }

  assert {
    condition     = length(google_storage_transfer_job.replication) == 1
    error_message = "A secondary region must add the transfer job."
  }
}
