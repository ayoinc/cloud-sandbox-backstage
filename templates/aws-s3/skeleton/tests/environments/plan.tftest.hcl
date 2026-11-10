# Plans the configuration with the variables of one environment file against
# mocked providers, so a broken environments/*.tfvars is caught without an AWS
# account:
#   terraform test -test-directory=tests/environments -var-file=environments/dev.tfvars

mock_provider "aws" {}

run "plan" {
  command = plan

  assert {
    condition     = output.bucket_id == "${var.org_prefix}-${var.name}-${var.environment}"
    error_message = "The bucket name must be <org_prefix>-<name>-<environment>."
  }
}
