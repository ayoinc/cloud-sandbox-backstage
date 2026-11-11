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
  auto_shutdown_schedule    = null
  create_resource_container = true
}

run "machine_is_private_and_hardened" {
  command = plan

  assert {
    condition     = aws_instance.this.metadata_options[0].http_tokens == "required"
    error_message = "The machine must require IMDSv2."
  }

  assert {
    condition     = aws_instance.this.root_block_device[0].encrypted
    error_message = "The root volume must be encrypted."
  }

  assert {
    condition     = length(aws_scheduler_schedule.vm_shutdown) == 0
    error_message = "No shutdown schedule unless auto_shutdown_schedule is set."
  }
}

run "shutdown_schedule_outside_production" {
  command = plan

  variables {
    auto_shutdown_schedule = "0 19 * * 1-5"
  }

  assert {
    condition     = aws_scheduler_schedule.vm_shutdown[0].schedule_expression == "cron(0 19 ? * MON-FRI *)"
    error_message = "The cron expression must be converted to the EventBridge Scheduler format."
  }
}

run "shutdown_schedule_every_day" {
  command = plan

  variables {
    environment            = "staging"
    auto_shutdown_schedule = "30 22 * * *"
  }

  assert {
    condition     = aws_scheduler_schedule.vm_shutdown[0].schedule_expression == "cron(30 22 * * ? *)"
    error_message = "A schedule for every day must use the day-of-month wildcard."
  }
}

run "production_is_never_shut_down" {
  command = plan

  variables {
    environment            = "production"
    auto_shutdown_schedule = "0 19 * * 1-5"
  }

  assert {
    condition     = length(aws_scheduler_schedule.vm_shutdown) == 0
    error_message = "Production machines must not be stopped on a schedule."
  }
}

run "rejects_unsupported_cron" {
  command = plan

  variables {
    auto_shutdown_schedule = "*/5 * * * *"
  }

  expect_failures = [var.auto_shutdown_schedule]
}
