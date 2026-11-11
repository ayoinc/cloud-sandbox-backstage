# Plans the configuration with the variables of one environment file against
# mocked providers, so a broken environments/*.tfvars is caught without an
# account:
#   terraform test -test-directory=tests/environments -var-file=environments/${{ values.envName }}.tfvars

mock_provider "helm" {}
mock_provider "kubernetes" {}

variables {
  dns_api_token = "token-used-by-the-tests"
}

run "plan" {
  command = plan

  assert {
    condition     = length(helm_release.cert_manager) == (var.enable_cert_manager ? 1 : 0)
    error_message = "cert-manager must be planned exactly when it is enabled."
  }
}
