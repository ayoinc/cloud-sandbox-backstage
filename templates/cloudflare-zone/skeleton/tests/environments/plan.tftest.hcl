# Plans the configuration with the variables of one environment file against
# mocked providers, so a broken environments/*.tfvars is caught without an
# account:
#   terraform test -test-directory=tests/environments -var-file=environments/prod.tfvars

mock_provider "cloudflare" {}

variables {
  account_id = "0123456789abcdef0123456789abcdef"
}

run "plan" {
  command = plan

  assert {
    condition     = cloudflare_zone_setting.this["ssl"].value == var.ssl_mode
    error_message = "The zone must use the configured encryption mode."
  }
}
