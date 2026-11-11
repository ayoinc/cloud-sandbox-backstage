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

run "key_rotates" {
  command = plan

  assert {
    condition     = aws_kms_key.this.enable_key_rotation
    error_message = "The key must rotate."
  }

  assert {
    condition     = aws_kms_alias.this.name == "alias/example-org-billing-dev-kms-001"
    error_message = "The alias follows the naming convention."
  }

  assert {
    condition     = aws_kms_key.this.deletion_window_in_days == 7
    error_message = "Outside production a deleted key is kept for 7 days."
  }
}

run "production_keeps_deleted_keys_longer" {
  command = plan

  variables {
    environment = "production"
  }

  assert {
    condition     = aws_kms_key.this.deletion_window_in_days == 30
    error_message = "In production a deleted key is kept for 30 days."
  }
}
