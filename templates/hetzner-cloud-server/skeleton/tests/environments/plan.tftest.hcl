# Plans the configuration with the variables of one environment file against
# mocked providers, so a broken environments/*.tfvars is caught without an
# account:
#   terraform test -test-directory=tests/environments -var-file=environments/dev.tfvars

mock_provider "hcloud" {
  mock_data "hcloud_ssh_key" {
    defaults = {
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMockedKeyForTestsOnly0000000000000000000000 tests"
    }
  }
}

run "plan" {
  command = plan

  assert {
    condition     = length(hcloud_server.this) == var.server_count
    error_message = "The configured number of servers must be planned."
  }
}
