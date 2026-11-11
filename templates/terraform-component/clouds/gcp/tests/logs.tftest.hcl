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
  create_resource_container = true
  project_id                = ""
  billing_account           = "000000-AAAAAA-000000"
  folder_id                 = "folders/123456789"
}

run "log_bucket_has_retention" {
  command = plan

  assert {
    condition     = google_logging_project_bucket_config.this.retention_days == 30
    error_message = "Logs are kept for log_retention_days."
  }

  assert {
    condition     = google_logging_project_bucket_config.this.bucket_id == "example-org-billing-dev-log-001"
    error_message = "The log bucket follows the naming convention."
  }
}

run "rejects_invalid_retention" {
  command = plan

  variables {
    log_retention_days = 0
  }

  expect_failures = [var.log_retention_days]
}
