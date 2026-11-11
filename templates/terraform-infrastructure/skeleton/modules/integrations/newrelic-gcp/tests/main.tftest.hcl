mock_provider "google" {
  mock_data "google_client_config" {
    defaults = {
      project = "provider-project"
    }
  }
}

mock_provider "newrelic" {
  mock_data "newrelic_account" {
    defaults = {
      id = "7654321"
    }
  }
}

mock_provider "random" {
  mock_resource "random_id" {
    override_during = plan
    defaults = {
      hex = "a1b2"
    }
  }
}

mock_provider "time" {}

variables {
  name_prefix = "acme-dev"
  tags = {
    Project     = "acme"
    Environment = "development"
  }
}

run "links_the_provider_project" {
  command = plan

  assert {
    condition     = newrelic_cloud_gcp_link_account.this.project_id == "provider-project" && newrelic_cloud_gcp_link_account.this.account_id == 7654321
    error_message = "The project of the google provider must be linked to the account of the newrelic provider."
  }

  assert {
    condition     = newrelic_cloud_gcp_link_account.this.use_workload_identity_federation
    error_message = "The project must be linked without a service account key."
  }

  assert {
    condition     = google_service_account.newrelic.account_id == "acme-dev-relic" && google_service_account.newrelic.project == "provider-project"
    error_message = "The service account must derive its ID from name_prefix and live in the monitored project."
  }

  assert {
    condition     = google_iam_workload_identity_pool.newrelic.workload_identity_pool_id == "nr-acme-dev-a1b2"
    error_message = "The pool ID must derive from name_prefix and the random suffix."
  }

  assert {
    condition     = google_iam_workload_identity_pool_provider.newrelic.oidc[0].issuer_uri == "https://oidc.newrelic.com/r/gcp-cmp"
    error_message = "A US account must trust the US issuer."
  }

  assert {
    condition     = google_iam_workload_identity_pool_provider.newrelic.attribute_condition == "assertion.nr_account_id == \"7654321\""
    error_message = "The provider must reject tokens of other New Relic accounts."
  }

  assert {
    condition     = google_service_account_iam_member.newrelic_impersonation.role == "roles/iam.workloadIdentityUser"
    error_message = "The pool must be allowed to impersonate the service account."
  }

  assert {
    condition     = toset(keys(google_project_iam_member.newrelic)) == toset(["roles/cloudasset.viewer", "roles/monitoring.viewer", "roles/serviceusage.serviceUsageConsumer"])
    error_message = "New Relic must hold the three predefined read-only roles only."
  }

  assert {
    condition = alltrue([
      for permission in google_project_iam_custom_role.newrelic.permissions :
      can(regex("\\.(get|list)$", permission))
    ])
    error_message = "The custom role may only contain get and list permissions."
  }

  assert {
    condition     = google_project_iam_custom_role.newrelic.role_id == "acme_dev_newrelic_inventory"
    error_message = "The custom role ID must derive from name_prefix without hyphens."
  }

  assert {
    condition = alltrue([
      for integration in ["router", "load_balancing", "kubernetes", "virtual_machines", "sql", "redis", "storage"] :
      length(newrelic_cloud_gcp_dm_integrations.this[integration]) == 1
    ])
    error_message = "Every service the stack can create must have its integration enabled."
  }
}

run "links_explicit_project_and_account" {
  command = plan

  variables {
    project_id          = "acme-observability"
    newrelic_account_id = 1234567
    newrelic_region     = "EU"
  }

  assert {
    condition     = length(data.google_client_config.current) == 0 && length(data.newrelic_account.current) == 0
    error_message = "Nothing is looked up when project and account are passed."
  }

  assert {
    condition     = newrelic_cloud_gcp_link_account.this.project_id == "acme-observability" && newrelic_cloud_gcp_link_account.this.account_id == 1234567
    error_message = "The given project must be linked to the given account."
  }

  assert {
    condition     = google_iam_workload_identity_pool_provider.newrelic.oidc[0].issuer_uri == "https://oidc.eu.newrelic.com/r/gcp-cmp"
    error_message = "An EU account must trust the EU issuer."
  }

  assert {
    condition     = google_iam_workload_identity_pool_provider.newrelic.attribute_condition == "assertion.nr_account_id == \"1234567\""
    error_message = "The provider must accept tokens of the given account only."
  }
}

run "keeps_names_within_limits" {
  command = plan

  variables {
    name_prefix = "abcdefghijklmnopqrstuvwx"
    tags = {
      Description = "It's the team's \"main\" service: handles 50% of #1 & more"
      Padding     = join("", [for index in range(40) : "0123456789"])
    }
  }

  assert {
    condition     = length(google_service_account.newrelic.account_id) <= 30
    error_message = "The service account ID must stay within 30 characters."
  }

  assert {
    condition     = length(google_iam_workload_identity_pool.newrelic.workload_identity_pool_id) <= 32
    error_message = "The pool ID must stay within 32 characters."
  }

  assert {
    condition     = length(google_service_account.newrelic.description) == 256
    error_message = "The description must be cut at the 256 character limit."
  }

  assert {
    condition     = strcontains(google_service_account.newrelic.description, "Description=It's the team's \"main\" service: handles 50% of #1 & more")
    error_message = "Tag values must be recorded verbatim in the description."
  }
}

run "rejects_unknown_region" {
  command = plan

  variables {
    newrelic_region = "APAC"
  }

  expect_failures = [var.newrelic_region]
}

run "rejects_name_prefix_starting_with_digit" {
  command = plan

  variables {
    name_prefix = "1acme"
  }

  expect_failures = [var.name_prefix]
}
