# =============================================================================
# DigitalOcean Kubernetes - VPC, cluster, node pools and registry
# =============================================================================

locals {
  cluster_name = "${var.name}-${var.environment}"

  # Tags may hold letters, digits, colons, dashes and underscores only.
  tags = [
    "terraform",
    "env:${var.environment}",
    "owner:${replace(var.owner, "/[^A-Za-z0-9:_-]/", "-")}",
  ]

  project_environment = {
    dev     = "Development"
    staging = "Staging"
    prod    = "Production"
  }
}

# Latest patch release of the chosen minor version.
data "digitalocean_kubernetes_versions" "this" {
  version_prefix = "${var.kubernetes_version}."
}

resource "digitalocean_vpc" "this" {
  name        = "${local.cluster_name}-vpc"
  region      = var.region
  ip_range    = var.vpc_cidr
  description = substr(var.description, 0, 255)
}

resource "digitalocean_container_registry" "this" {
  count = var.create_registry ? 1 : 0

  name                   = coalesce(var.registry_name, var.name)
  subscription_tier_slug = var.registry_tier
  region                 = var.region
}

resource "digitalocean_kubernetes_cluster" "this" {
  name     = local.cluster_name
  region   = var.region
  version  = data.digitalocean_kubernetes_versions.this.latest_version
  vpc_uuid = digitalocean_vpc.this.id

  ha            = var.ha_control_plane
  auto_upgrade  = var.auto_upgrade
  surge_upgrade = true

  registry_integration = var.registry_integration

  # Load balancers and volumes created from inside the cluster hold data and
  # addresses; they are not deleted behind the back of their owners.
  destroy_all_associated_resources = false

  tags = local.tags

  maintenance_policy {
    day        = var.maintenance_window.day
    start_time = var.maintenance_window.start_time
  }

  dynamic "control_plane_firewall" {
    for_each = length(var.control_plane_allowed_cidrs) > 0 ? [var.control_plane_allowed_cidrs] : []

    content {
      enabled           = true
      allowed_addresses = control_plane_firewall.value
    }
  }

  node_pool {
    name       = "${local.cluster_name}-default"
    size       = var.node_size
    auto_scale = true
    min_nodes  = var.min_nodes
    max_nodes  = var.max_nodes
    tags       = local.tags
    labels = {
      pool = "default"
    }
  }

  # The registry integration needs the registry to exist first.
  depends_on = [digitalocean_container_registry.this]
}

resource "digitalocean_kubernetes_node_pool" "this" {
  for_each = var.additional_node_pools

  cluster_id = digitalocean_kubernetes_cluster.this.id
  name       = "${local.cluster_name}-${each.key}"
  size       = each.value.size
  auto_scale = true
  min_nodes  = each.value.min_nodes
  max_nodes  = each.value.max_nodes
  tags       = local.tags
  labels     = merge(each.value.labels, { pool = each.key })

  dynamic "taint" {
    for_each = each.value.taints

    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }
}

# Groups the cluster in the control panel and on the invoice.
resource "digitalocean_project" "this" {
  name        = local.cluster_name
  description = substr(var.description, 0, 255)
  purpose     = "Service or API"
  environment = local.project_environment[var.environment]
  resources   = [digitalocean_kubernetes_cluster.this.urn]
}
