# Plans the configuration against a mocked provider: no DigitalOcean account
# is needed.   terraform init -backend=false && terraform test

mock_provider "digitalocean" {
  mock_data "digitalocean_ssh_key" {
    defaults = {
      id         = 1234
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMockedKeyForTestsOnly0000000000000000000000 tests"
    }
  }
}

variables {
  name          = "test-droplet"
  environment   = "dev"
  region        = "fra1"
  description   = "Droplets used by the tests"
  owner         = "group:default/platform-team"
  size          = "s-1vcpu-2gb"
  image         = "ubuntu-26-04-x64"
  vpc_cidr      = "10.210.0.0/24"
  ssh_key_names = ["platform-team"]
}

run "creates_a_hardened_droplet" {
  command = plan

  assert {
    condition     = digitalocean_droplet.this[0].name == "test-droplet-dev-01"
    error_message = "Droplets must be named <name>-<environment>-<number>."
  }

  assert {
    condition     = digitalocean_droplet.this[0].monitoring && digitalocean_droplet.this[0].ipv6
    error_message = "Monitoring and IPv6 must be enabled."
  }

  assert {
    condition     = strcontains(digitalocean_droplet.this[0].user_data, "PermitRootLogin no") && strcontains(digitalocean_droplet.this[0].user_data, "PasswordAuthentication no")
    error_message = "cloud-init must disable root and password sign-in."
  }

  assert {
    condition     = strcontains(digitalocean_droplet.this[0].user_data, "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMockedKeyForTestsOnly")
    error_message = "The SSH key must be installed for the admin user."
  }
}

run "is_closed_to_the_internet_by_default" {
  command = plan

  assert {
    condition     = alltrue([for rule in digitalocean_firewall.this.inbound_rule : !contains(rule.source_addresses, "0.0.0.0/0")])
    error_message = "No inbound rule may allow the whole internet by default."
  }

  assert {
    condition     = !contains([for rule in digitalocean_firewall.this.inbound_rule : rule.port_range], "22")
    error_message = "SSH must stay closed until a source range is given."
  }

  assert {
    condition     = length(digitalocean_reserved_ip.this) == 0
    error_message = "Reserved IPs must be opt-in."
  }
}

run "opens_only_what_is_asked_for" {
  command = plan

  variables {
    droplet_count     = 2
    ssh_allowed_cidrs = ["198.51.100.0/24"]
    allow_web         = true
    reserved_ip       = true
  }

  assert {
    condition     = one([for rule in digitalocean_firewall.this.inbound_rule : rule.source_addresses if rule.port_range == "22"]) == toset(["198.51.100.0/24"])
    error_message = "SSH must be limited to the given range."
  }

  assert {
    condition     = length([for rule in digitalocean_firewall.this.inbound_rule : rule if contains(["80", "443"], rule.port_range)]) == 2
    error_message = "HTTP and HTTPS must be allowed when allow_web is set."
  }

  assert {
    condition     = length(digitalocean_droplet.this) == 2 && length(digitalocean_reserved_ip_assignment.this) == 2
    error_message = "Every Droplet must get a reserved IP."
  }
}

run "rejects_ssh_from_anywhere" {
  command = plan

  variables {
    ssh_allowed_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.ssh_allowed_cidrs]
}

run "rejects_a_deployment_without_ssh_keys" {
  command = plan

  variables {
    ssh_key_names = []
  }

  expect_failures = [var.ssh_key_names]
}
