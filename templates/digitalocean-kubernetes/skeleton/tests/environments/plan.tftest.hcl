# Plans the configuration with the variables of one environment file against
# mocked providers, so a broken environments/*.tfvars is caught without an
# account:
#   terraform test -test-directory=tests/environments -var-file=environments/dev.tfvars

mock_provider "digitalocean" {
  mock_data "digitalocean_kubernetes_versions" {
    defaults = {
      latest_version = "1.37.2-do.0"
    }
  }
}

run "plan" {
  command = plan

  assert {
    condition     = digitalocean_kubernetes_cluster.this.name == "${var.name}-${var.environment}"
    error_message = "The cluster must be named <name>-<environment>."
  }
}
