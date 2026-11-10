# Plans the configuration with the variables of one environment file against
# mocked providers, so a broken environments/*.tfvars is caught without an AWS
# account:
#   terraform test -test-directory=tests/environments -var-file=environments/dev.tfvars

mock_provider "aws" {}

run "plan" {
  command = plan

  assert {
    condition     = output.price_class == var.price_class
    error_message = "The distribution must use the price class of the environment file."
  }
}
