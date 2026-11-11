mock_provider "google" {
  mock_data "google_client_config" {
    defaults = {
      project = "provider-project"
    }
  }
}

mock_provider "datadog" {}

variables {
  name_prefix = "acme-dev"
  tags = {
    Project     = "acme"
    Environment = "development"
  }
}

run "connects_the_provider_project" {
  command = plan

  assert {
    condition     = google_service_account.datadog.project == "provider-project"
    error_message = "The service account must be created in the project of the google provider."
  }

  assert {
    condition     = google_service_account.datadog.account_id == "acme-dev-ddog"
    error_message = "The service account ID must derive from name_prefix."
  }

  assert {
    condition     = toset(keys(google_project_iam_member.datadog)) == toset(["roles/browser", "roles/cloudasset.viewer", "roles/compute.viewer", "roles/monitoring.viewer"])
    error_message = "Datadog must hold exactly the read-only roles it documents."
  }

  assert {
    condition     = alltrue([for member in google_project_iam_member.datadog : member.project == "provider-project"])
    error_message = "The roles must be granted on the monitored project."
  }

  assert {
    condition     = google_service_account_iam_member.datadog_impersonation.role == "roles/iam.serviceAccountTokenCreator"
    error_message = "Datadog must be allowed to mint tokens of the service account."
  }

  assert {
    condition     = alltrue([for service in google_project_service.required : service.disable_on_destroy == false])
    error_message = "Removing the module must not switch APIs off."
  }

  assert {
    condition     = datadog_integration_gcp_sts.this.account_tags == toset(["Project:acme", "Environment:development"])
    error_message = "Tags must be sent to Datadog as key:value account tags."
  }

  assert {
    condition     = !datadog_integration_gcp_sts.this.is_cspm_enabled
    error_message = "Posture management must stay off."
  }
}

run "connects_an_explicit_project" {
  command = plan

  variables {
    project_id = "acme-observability"
  }

  assert {
    condition     = length(data.google_client_config.current) == 0
    error_message = "The provider configuration is not read when a project ID is passed."
  }

  assert {
    condition     = google_service_account.datadog.project == "acme-observability" && alltrue([for member in google_project_iam_member.datadog : member.project == "acme-observability"])
    error_message = "The service account and its roles must be created in the given project."
  }
}

run "accepts_longest_name_prefix" {
  command = plan

  variables {
    name_prefix = "abcdefghijklmnopqrstuvwx"
  }

  assert {
    condition     = length(google_service_account.datadog.account_id) <= 30
    error_message = "The service account ID must stay within 30 characters."
  }
}

run "rejects_name_prefix_starting_with_digit" {
  command = plan

  variables {
    name_prefix = "1acme"
  }

  expect_failures = [var.name_prefix]
}
