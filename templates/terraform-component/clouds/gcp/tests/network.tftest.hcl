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

run "public_and_private_subnets" {
  command = plan

  assert {
    condition     = google_compute_subnetwork.public.ip_cidr_range == "10.0.0.0/20" && google_compute_subnetwork.private.ip_cidr_range == "10.0.128.0/20"
    error_message = "Subnets are /4 slices of the network range."
  }

  assert {
    condition     = google_compute_network.this.auto_create_subnetworks == false
    error_message = "The network must only contain the subnets defined here."
  }

  assert {
    condition     = length(google_compute_router_nat.this) == 1
    error_message = "Cloud NAT is created by default."
  }
}

run "nat_gateway_can_be_switched_off" {
  command = plan

  variables {
    enable_nat_gateway = false
  }

  assert {
    condition     = length(google_compute_router_nat.this) == 0 && length(google_compute_router.this) == 0
    error_message = "No Cloud NAT when it is switched off."
  }
}
