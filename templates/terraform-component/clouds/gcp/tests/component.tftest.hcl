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

run "new_project_follows_the_conventions" {
  command = plan

  assert {
    condition     = length(google_project.this[0].name) <= 24
    error_message = "The project display name uses the short form of the name."
  }

  assert {
    condition     = google_project.this[0].auto_create_network == false
    error_message = "The project must not get the default network."
  }

  assert {
    condition     = google_project.this[0].deletion_policy == "DELETE"
    error_message = "Outside production the project can be deleted with the component."
  }

  assert {
    condition     = output.labels["component"] == "test-component" && output.labels["cost-center"] == "application-development"
    error_message = "Resources carry the standard labels."
  }
}

run "production_project_is_protected" {
  command = plan

  variables {
    environment = "production"
  }

  assert {
    condition     = google_project.this[0].deletion_policy == "PREVENT"
    error_message = "A production project must be protected from deletion."
  }
}

run "new_project_needs_folder_and_billing" {
  command = plan

  variables {
    billing_account = ""
  }

  expect_failures = [google_project.this]
}

run "existing_project" {
  command = plan

  variables {
    create_resource_container = false
    project_id                = "existing-project"
  }

  assert {
    condition     = length(google_project.this) == 0 && output.project_id == "existing-project"
    error_message = "No project is created when an existing one is used."
  }
}

run "existing_project_needs_an_id" {
  command = plan

  variables {
    create_resource_container = false
  }

  expect_failures = [data.google_project.existing]
}
