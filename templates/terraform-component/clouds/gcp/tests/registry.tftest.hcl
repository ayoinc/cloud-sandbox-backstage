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

run "repository_holds_immutable_container_images" {
  command = plan

  assert {
    condition     = google_artifact_registry_repository.this.format == "DOCKER"
    error_message = "The repository must hold container images."
  }

  assert {
    condition     = google_artifact_registry_repository.this.docker_config[0].immutable_tags
    error_message = "Image tags must be immutable."
  }

  assert {
    condition     = google_artifact_registry_repository.this.repository_id == "example-org-billing-dev-ar-001"
    error_message = "The repository follows the naming convention."
  }
}
