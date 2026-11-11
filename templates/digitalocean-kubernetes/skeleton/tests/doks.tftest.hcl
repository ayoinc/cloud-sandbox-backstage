# Plans the configuration against a mocked provider: no DigitalOcean account
# is needed.   terraform init -backend=false && terraform test

mock_provider "digitalocean" {
  mock_data "digitalocean_kubernetes_versions" {
    defaults = {
      latest_version = "1.37.2-do.0"
    }
  }
}

variables {
  name               = "test-doks"
  environment        = "dev"
  region             = "fra1"
  description        = "Cluster used by the tests"
  owner              = "group:default/platform-team"
  kubernetes_version = "1.37"
  vpc_cidr           = "10.110.0.0/20"
  node_size          = "s-2vcpu-4gb"
  min_nodes          = 1
  max_nodes          = 3
}

run "creates_an_autoscaling_cluster_in_its_own_vpc" {
  command = plan

  assert {
    condition     = digitalocean_kubernetes_cluster.this.name == "test-doks-dev"
    error_message = "The cluster must be named <name>-<environment>."
  }

  assert {
    condition     = digitalocean_kubernetes_cluster.this.version == "1.37.2-do.0"
    error_message = "The cluster must run the latest patch release of the chosen minor version."
  }

  assert {
    condition     = digitalocean_kubernetes_cluster.this.node_pool[0].auto_scale && digitalocean_kubernetes_cluster.this.node_pool[0].max_nodes == 3
    error_message = "The default node pool must autoscale up to max_nodes."
  }

  assert {
    condition     = digitalocean_vpc.this.ip_range == "10.110.0.0/20"
    error_message = "The cluster must get its own VPC."
  }

  assert {
    condition     = digitalocean_kubernetes_cluster.this.surge_upgrade && digitalocean_kubernetes_cluster.this.auto_upgrade
    error_message = "Patch releases must be installed automatically with surge upgrades."
  }
}

run "tags_are_valid_for_digitalocean" {
  command = plan

  assert {
    condition     = alltrue([for tag in local.tags : can(regex("^[A-Za-z0-9:_-]+$", tag))])
    error_message = "Tags may hold letters, digits, colons, dashes and underscores only."
  }

  assert {
    condition     = contains(local.tags, "owner:group:default-platform-team")
    error_message = "The owner must be added as a tag."
  }
}

run "does_not_create_a_registry_by_default" {
  command = plan

  assert {
    condition     = length(digitalocean_container_registry.this) == 0
    error_message = "The registry is shared by the account; it must only be created on request."
  }
}

run "creates_the_registry_and_extra_node_pools" {
  command = plan

  variables {
    create_registry = true
    additional_node_pools = {
      batch = {
        size      = "c-4"
        min_nodes = 0
        max_nodes = 4
        taints = [
          {
            key    = "workload"
            value  = "batch"
            effect = "NoSchedule"
          },
        ]
      }
    }
  }

  assert {
    condition     = digitalocean_container_registry.this[0].name == "test-doks"
    error_message = "The registry must be named after the cluster unless registry_name is set."
  }

  assert {
    condition     = digitalocean_kubernetes_node_pool.this["batch"].name == "test-doks-dev-batch"
    error_message = "Additional node pools must be named <cluster>-<key>."
  }
}

run "restricts_the_api_to_the_allowed_addresses" {
  command = plan

  variables {
    control_plane_allowed_cidrs = ["198.51.100.0/24"]
  }

  assert {
    condition     = digitalocean_kubernetes_cluster.this.control_plane_firewall[0].enabled
    error_message = "The control plane firewall must be enabled when addresses are given."
  }
}

run "rejects_a_node_pool_that_cannot_scale" {
  command = plan

  variables {
    min_nodes = 4
    max_nodes = 2
  }

  expect_failures = [var.max_nodes]
}
