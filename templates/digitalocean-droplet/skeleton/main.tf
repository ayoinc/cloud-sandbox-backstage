# =============================================================================
# DigitalOcean Droplets - VPC, Droplets, firewall and reserved IPs
# =============================================================================

locals {
  name = "${var.name}-${var.environment}"

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

  anywhere = ["0.0.0.0/0", "::/0"]
}

data "digitalocean_ssh_key" "this" {
  for_each = toset(var.ssh_key_names)

  name = each.value
}

resource "digitalocean_vpc" "this" {
  name        = "${local.name}-vpc"
  region      = var.region
  ip_range    = var.vpc_cidr
  description = substr(var.description, 0, 255)
}

resource "digitalocean_droplet" "this" {
  count = var.droplet_count

  name     = format("%s-%02d", local.name, count.index + 1)
  region   = var.region
  size     = var.size
  image    = var.image
  vpc_uuid = digitalocean_vpc.this.id

  # Supplying a key keeps DigitalOcean from e-mailing a root password. Root
  # sign-in is then disabled by cloud-init in favour of the admin user.
  ssh_keys = [for key in data.digitalocean_ssh_key.this : key.id]
  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    admin_user      = var.admin_user
    ssh_public_keys = [for key in data.digitalocean_ssh_key.this : key.public_key]
  })

  monitoring        = true
  droplet_agent     = true
  ipv6              = true
  backups           = var.enable_backups
  graceful_shutdown = true
  tags              = local.tags
}

# The firewall denies everything that no rule allows. Outbound traffic stays
# open: the Droplets fetch package updates and call other services, whose
# addresses are not known in advance.
# trivy:ignore:DIG-0003
resource "digitalocean_firewall" "this" {
  name        = local.name
  droplet_ids = digitalocean_droplet.this[*].id

  dynamic "inbound_rule" {
    for_each = length(var.ssh_allowed_cidrs) > 0 ? [var.ssh_allowed_cidrs] : []

    content {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = inbound_rule.value
    }
  }

  dynamic "inbound_rule" {
    for_each = var.allow_web ? ["80", "443"] : []

    content {
      protocol         = "tcp"
      port_range       = inbound_rule.value
      source_addresses = local.anywhere
    }
  }

  # Traffic between the Droplets and other resources of the VPC.
  inbound_rule {
    protocol         = "tcp"
    port_range       = "1-65535"
    source_addresses = [digitalocean_vpc.this.ip_range]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "1-65535"
    source_addresses = [digitalocean_vpc.this.ip_range]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = [digitalocean_vpc.this.ip_range]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = local.anywhere
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = local.anywhere
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = local.anywhere
  }
}

resource "digitalocean_reserved_ip" "this" {
  count = var.reserved_ip ? var.droplet_count : 0

  region = var.region
}

resource "digitalocean_reserved_ip_assignment" "this" {
  count = var.reserved_ip ? var.droplet_count : 0

  ip_address = digitalocean_reserved_ip.this[count.index].ip_address
  droplet_id = digitalocean_droplet.this[count.index].id
}

# Groups the Droplets in the control panel and on the invoice.
resource "digitalocean_project" "this" {
  name        = local.name
  description = substr(var.description, 0, 255)
  purpose     = "Service or API"
  environment = local.project_environment[var.environment]
  resources   = digitalocean_droplet.this[*].urn
}
