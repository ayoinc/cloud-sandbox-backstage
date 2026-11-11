# Plans the configuration with the variables of one environment file against
# mocked providers, so a broken environments/*.tfvars is caught without an
# account:
#   terraform test -test-directory=tests/environments -var-file=environments/dev.tfvars

mock_provider "cloudflare" {}
mock_provider "random" {}

variables {
  account_id = "0123456789abcdef0123456789abcdef"
}

run "plan" {
  command = plan

  assert {
    condition     = cloudflare_workers_script.this.script_name == "${var.name}-${var.environment}"
    error_message = "The Worker must be named <name>-<environment>."
  }
}
