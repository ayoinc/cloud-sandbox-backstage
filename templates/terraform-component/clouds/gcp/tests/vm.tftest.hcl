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
  auto_shutdown_schedule    = null
  create_resource_container = true
  project_id                = ""
  billing_account           = "000000-AAAAAA-000000"
  folder_id                 = "folders/123456789"
}

run "machine_is_private_and_shielded" {
  command = plan

  assert {
    condition     = length(google_compute_instance.this.network_interface[0].access_config) == 0
    error_message = "The machine must not have an external IP address."
  }

  assert {
    condition     = google_compute_instance.this.shielded_instance_config[0].enable_secure_boot
    error_message = "The machine must use secure boot."
  }

  assert {
    condition     = google_compute_firewall.vm_iap_ssh.source_ranges == toset(["35.235.240.0/20"])
    error_message = "SSH must be open to the Identity-Aware Proxy range only."
  }

  assert {
    condition     = length(google_compute_resource_policy.vm_shutdown) == 0
    error_message = "No shutdown schedule unless auto_shutdown_schedule is set."
  }
}

run "shutdown_schedule_outside_production" {
  command = plan

  variables {
    auto_shutdown_schedule = "0 19 * * 1-5"
  }

  assert {
    condition     = google_compute_resource_policy.vm_shutdown[0].instance_schedule_policy[0].vm_stop_schedule[0].schedule == "0 19 * * 1-5"
    error_message = "The cron expression is the stop schedule."
  }
}

run "production_is_never_shut_down" {
  command = plan

  variables {
    environment            = "production"
    auto_shutdown_schedule = "0 19 * * 1-5"
  }

  assert {
    condition     = length(google_compute_resource_policy.vm_shutdown) == 0
    error_message = "Production machines must not be stopped on a schedule."
  }
}
