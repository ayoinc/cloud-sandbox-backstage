# Plan-only tests against mocked providers: no credentials, no resources.

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }

  mock_data "aws_ami" {
    defaults = {
      id = "ami-0123456789abcdef0"
    }
  }
}

mock_provider "aws" {
  alias = "secondary"
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
  region                    = "us-east-1"
  create_resource_container = true
}

run "names_and_tags_follow_the_conventions" {
  command = plan

  assert {
    condition     = aws_resourcegroups_group.this[0].name == "example-org-billing-dev-rg-001"
    error_message = "The enterprise convention is company-project-env-type-instance."
  }

  assert {
    condition     = output.tags["Component"] == "test-component" && output.tags["Environment"] == "development" && output.tags["CostCenter"] == "application-development"
    error_message = "Resources carry the standard tags."
  }
}

run "team_naming_convention" {
  command = plan

  variables {
    naming_convention = "team"
  }

  assert {
    condition     = aws_resourcegroups_group.this[0].name == "engineering-billing-rg-dev-001"
    error_message = "The team convention is team-project-type-env-instance."
  }
}

run "resource_container_is_optional" {
  command = plan

  variables {
    create_resource_container = false
  }

  assert {
    condition     = length(aws_resourcegroups_group.this) == 0
    error_message = "No resource group when create_resource_container is false."
  }
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "qa"
  }

  expect_failures = [var.environment]
}
