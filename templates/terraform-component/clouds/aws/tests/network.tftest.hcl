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

run "two_zones_public_and_private" {
  command = plan

  assert {
    condition     = aws_subnet.public[*].cidr_block == ["10.0.0.0/20", "10.0.16.0/20"]
    error_message = "Public subnets must be the first /20 blocks of the VPC."
  }

  assert {
    condition     = aws_subnet.private[*].cidr_block == ["10.0.128.0/20", "10.0.144.0/20"]
    error_message = "Private subnets must start at the ninth /20 block of the VPC."
  }

  assert {
    condition     = aws_subnet.private[*].availability_zone == ["us-east-1a", "us-east-1b"]
    error_message = "Subnets must be spread over two availability zones."
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "Private subnets get a NAT gateway by default."
  }
}

run "nat_gateway_can_be_switched_off" {
  command = plan

  variables {
    enable_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_route.private_nat) == 0
    error_message = "No NAT gateway when it is switched off."
  }
}
