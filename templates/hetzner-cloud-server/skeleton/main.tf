# =============================================================================
# Hetzner Cloud Servers - Network, firewall, servers and load balancer
# =============================================================================

locals {
  name = "${var.name}-${var.environment}"

  network_zones = {
    fsn1 = "eu-central"
    nbg1 = "eu-central"
    hel1 = "eu-central"
    ash  = "us-east"
    hil  = "us-west"
    sin  = "ap-southeast"
  }

  # Label values may hold letters, digits, dashes, underscores and dots only.
  labels = {
    project     = var.name
    environment = var.environment
    owner       = trim(substr(replace(var.owner, "/[^A-Za-z0-9_.-]/", "_"), 0, 63), "_.-")
    managed-by  = "terraform"
  }

  # Selects the servers of this deployment as load balancer targets.
  label_selector = "project=${var.name},environment=${var.environment}"

  anywhere = ["0.0.0.0/0", "::/0"]
}

data "hcloud_ssh_key" "this" {
  for_each = toset(var.ssh_key_names)

  name = each.value
}

# -----------------------------------------------------------------------------
# Private network
# -----------------------------------------------------------------------------

resource "hcloud_network" "this" {
  name     = local.name
  ip_range = var.network_cidr
  labels   = local.labels
}

resource "hcloud_network_subnet" "this" {
  network_id   = hcloud_network.this.id
  type         = "cloud"
  network_zone = local.network_zones[var.location]
  ip_range     = var.network_cidr
}

# -----------------------------------------------------------------------------
# Firewall
# -----------------------------------------------------------------------------

# Inbound traffic that no rule allows is dropped. Traffic on the private
# network does not pass the firewall.
resource "hcloud_firewall" "this" {
  name   = local.name
  labels = local.labels

  dynamic "rule" {
    for_each = length(var.ssh_allowed_cidrs) > 0 ? [var.ssh_allowed_cidrs] : []

    content {
      description = "SSH from the administration networks"
      direction   = "in"
      protocol    = "tcp"
      port        = "22"
      source_ips  = rule.value
    }
  }

  dynamic "rule" {
    for_each = var.allow_web && !var.load_balancer ? ["80", "443"] : []

    content {
      description = "Web traffic from the internet"
      direction   = "in"
      protocol    = "tcp"
      port        = rule.value
      source_ips  = local.anywhere
    }
  }
}

# -----------------------------------------------------------------------------
# Servers
# -----------------------------------------------------------------------------

# Keeps the servers on different physical hosts.
resource "hcloud_placement_group" "this" {
  name   = local.name
  type   = "spread"
  labels = local.labels
}

resource "hcloud_server" "this" {
  count = var.server_count

  name        = format("%s-%02d", local.name, count.index + 1)
  server_type = var.server_type
  image       = var.image
  location    = var.location
  labels      = local.labels

  ssh_keys = [for key in data.hcloud_ssh_key.this : key.name]
  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    admin_user      = var.admin_user
    ssh_public_keys = [for key in data.hcloud_ssh_key.this : key.public_key]
  })

  firewall_ids       = [hcloud_firewall.this.id]
  placement_group_id = hcloud_placement_group.this.id

  backups                  = var.enable_backups
  delete_protection        = var.protection
  rebuild_protection       = var.protection
  shutdown_before_deletion = true

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.this.id
    ip         = cidrhost(var.network_cidr, 10 + count.index)
    alias_ips  = []
  }

  # The subnet must exist before a server can be attached to the network.
  depends_on = [hcloud_network_subnet.this]
}

# -----------------------------------------------------------------------------
# Load balancer (optional)
# -----------------------------------------------------------------------------

resource "hcloud_load_balancer" "this" {
  count = var.load_balancer ? 1 : 0

  name               = local.name
  load_balancer_type = var.load_balancer_type
  location           = var.location
  labels             = local.labels
  delete_protection  = var.protection

  algorithm {
    type = "round_robin"
  }
}

resource "hcloud_load_balancer_network" "this" {
  count = var.load_balancer ? 1 : 0

  load_balancer_id = hcloud_load_balancer.this[0].id
  subnet_id        = hcloud_network_subnet.this.id
}

resource "hcloud_load_balancer_target" "this" {
  count = var.load_balancer ? 1 : 0

  type             = "label_selector"
  load_balancer_id = hcloud_load_balancer.this[0].id
  label_selector   = local.label_selector
  use_private_ip   = true

  depends_on = [hcloud_load_balancer_network.this]
}

# TLS is passed through to the servers, which hold the certificates.
resource "hcloud_load_balancer_service" "this" {
  for_each = var.load_balancer ? toset(["80", "443"]) : toset([])

  load_balancer_id = hcloud_load_balancer.this[0].id
  protocol         = "tcp"
  listen_port      = tonumber(each.value)
  destination_port = tonumber(each.value)

  health_check {
    protocol = "tcp"
    port     = tonumber(each.value)
    interval = 15
    timeout  = 10
    retries  = 3
  }
}
