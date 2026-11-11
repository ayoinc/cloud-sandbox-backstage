# Plans the configuration with the variables of one environment file against
# mocked providers, so a broken environments/*.tfvars is caught without an
# account:
#   terraform test -test-directory=tests/environments -var-file=environments/dev.tfvars

mock_provider "digitalocean" {
  mock_data "digitalocean_ssh_key" {
    defaults = {
      id         = 1234
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMockedKeyForTestsOnly0000000000000000000000 tests"
    }
  }
}

run "plan" {
  command = plan

  assert {
    condition     = length(digitalocean_droplet.this) == var.droplet_count
    error_message = "The configured number of Droplets must be planned."
  }
}
