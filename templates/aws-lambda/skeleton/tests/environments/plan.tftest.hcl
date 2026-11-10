# Plans the configuration with the variables of one environment file against
# mocked providers, so a broken environments/*.tfvars is caught without an AWS
# account:
#   terraform test -test-directory=tests/environments -var-file=environments/dev.tfvars

mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock"
    }
  }
}

mock_provider "archive" {}

run "plan" {
  command = plan

  assert {
    condition     = output.function_name == "${var.name}-${var.environment}"
    error_message = "The function name must be <name>-<environment>."
  }
}
