# Plans the configuration against a mocked provider: no Hetzner account is
# needed.   terraform init -backend=false && terraform test

mock_provider "hcloud" {
  mock_data "hcloud_ssh_key" {
    defaults = {
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMockedKeyForTestsOnly0000000000000000000000 tests"
    }
  }
}

variables {
  name          = "test-server"
  environment   = "dev"
  location      = "fsn1"
  owner         = "group:default/platform-team"
  server_type   = "cpx22"
  image         = "ubuntu-26.04"
  network_cidr  = "10.10.0.0/24"
  ssh_key_names = ["platform-team"]
}

run "creates_a_hardened_server_on_the_private_network" {
  command = plan

  assert {
    condition     = hcloud_server.this[0].name == "test-server-dev-01"
    error_message = "Servers must be named <name>-<environment>-<number>."
  }

  assert {
    condition     = one(hcloud_server.this[0].network).ip == "10.10.0.10"
    error_message = "The first server must get the .10 address of the private network."
  }

  assert {
    condition     = hcloud_network_subnet.this.network_zone == "eu-central"
    error_message = "The subnet must be in the network zone of the location."
  }

  assert {
    condition     = strcontains(hcloud_server.this[0].user_data, "PermitRootLogin no") && strcontains(hcloud_server.this[0].user_data, "PasswordAuthentication no")
    error_message = "cloud-init must disable root and password sign-in."
  }
}

run "labels_are_valid_for_hetzner" {
  command = plan

  assert {
    condition     = local.labels.owner == "group_default_platform-team"
    error_message = "The owner must be turned into a valid label value."
  }
}

run "is_closed_to_the_internet_by_default" {
  command = plan

  assert {
    condition     = length(hcloud_firewall.this.rule) == 0
    error_message = "The firewall must have no inbound rule by default."
  }

  assert {
    condition     = length(hcloud_load_balancer.this) == 0
    error_message = "The load balancer must be opt-in."
  }
}

run "opens_ssh_and_web_when_asked" {
  command = plan

  variables {
    ssh_allowed_cidrs = ["198.51.100.0/24"]
    allow_web         = true
  }

  assert {
    condition     = length(hcloud_firewall.this.rule) == 3
    error_message = "SSH, HTTP and HTTPS must each get a rule."
  }
}

run "serves_through_the_load_balancer" {
  command = plan

  variables {
    server_count  = 2
    load_balancer = true
    allow_web     = true
  }

  assert {
    condition     = length(hcloud_firewall.this.rule) == 0
    error_message = "Behind the load balancer the servers must not accept web traffic from the internet."
  }

  assert {
    condition     = hcloud_load_balancer_target.this[0].use_private_ip && hcloud_load_balancer_target.this[0].label_selector == "project=test-server,environment=dev"
    error_message = "The load balancer must reach the servers of this deployment over the private network."
  }

  assert {
    condition     = length(hcloud_load_balancer_service.this) == 2
    error_message = "The load balancer must forward ports 80 and 443."
  }
}

run "rejects_ssh_from_anywhere" {
  command = plan

  variables {
    ssh_allowed_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.ssh_allowed_cidrs]
}

run "rejects_an_unknown_location" {
  command = plan

  variables {
    location = "moon1"
  }

  expect_failures = [var.location]
}
