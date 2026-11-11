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

run "log_group_has_retention" {
  command = plan

  assert {
    condition     = aws_cloudwatch_log_group.this.name == "/billing/development/test-component"
    error_message = "The log group is named after project, environment and component."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.retention_in_days == 30
    error_message = "Logs are kept for log_retention_days."
  }
}

run "rejects_unsupported_retention" {
  command = plan

  variables {
    log_retention_days = 45
  }

  expect_failures = [var.log_retention_days]
}
