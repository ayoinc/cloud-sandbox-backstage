# =============================================================================
# GCP VPC MODULE
# =============================================================================
# Creates VPC network with subnets, firewall rules, and Cloud NAT
# Follows Google Cloud best practices
# Provider version: ~> 5.0
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "routing_mode" {
  description = "Routing mode (GLOBAL or REGIONAL)"
  type        = string
  default     = "GLOBAL"
}

variable "auto_create_subnetworks" {
  description = "Auto-create subnetworks"
  type        = bool
  default     = false
}

variable "delete_default_routes_on_create" {
  description = "Delete default routes on creation"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "Subnet configurations"
  type = map(object({
    ip_cidr_range            = string
    region                   = optional(string)
    private_ip_google_access = optional(bool, true)
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
    log_config = optional(object({
      aggregation_interval = optional(string, "INTERVAL_5_SEC")
      flow_sampling        = optional(number, 0.5)
      metadata             = optional(string, "INCLUDE_ALL_METADATA")
    }), null)
  }))
  default = {
    default = {
      ip_cidr_range = "10.0.0.0/24"
    }
  }
}

variable "enable_nat" {
  description = "Enable Cloud NAT"
  type        = bool
  default     = true
}

variable "nat_ip_allocate_option" {
  description = "NAT IP allocation (AUTO_ONLY or MANUAL_ONLY)"
  type        = string
  default     = "AUTO_ONLY"
}

variable "firewall_rules" {
  description = "Firewall rules to create"
  type = map(object({
    description   = optional(string)
    direction     = optional(string, "INGRESS")
    priority      = optional(number, 1000)
    source_ranges = optional(list(string), [])
    target_tags   = optional(list(string), [])
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
  }))
  default = {}
}

variable "enable_private_google_access" {
  description = "Enable Private Google Access on subnets"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  network_name = "${var.name}-${var.environment}-vpc"

  common_labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })
}

# -----------------------------------------------------------------------------
# VPC Network
# -----------------------------------------------------------------------------

resource "google_compute_network" "main" {
  project                         = var.project_id
  name                            = local.network_name
  auto_create_subnetworks         = var.auto_create_subnetworks
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = var.delete_default_routes_on_create
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------

resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  project       = var.project_id
  name          = "${var.name}-${each.key}-${var.environment}"
  network       = google_compute_network.main.id
  ip_cidr_range = each.value.ip_cidr_range
  region        = coalesce(each.value.region, var.region)

  private_ip_google_access = each.value.private_ip_google_access

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ip_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []
    content {
      aggregation_interval = log_config.value.aggregation_interval
      flow_sampling        = log_config.value.flow_sampling
      metadata             = log_config.value.metadata
    }
  }
}

# -----------------------------------------------------------------------------
# Cloud Router (for NAT)
# -----------------------------------------------------------------------------

resource "google_compute_router" "main" {
  count = var.enable_nat ? 1 : 0

  project = var.project_id
  name    = "${var.name}-${var.environment}-router"
  network = google_compute_network.main.id
  region  = var.region

  bgp {
    asn = 64514
  }
}

# -----------------------------------------------------------------------------
# Cloud NAT
# -----------------------------------------------------------------------------

resource "google_compute_router_nat" "main" {
  count = var.enable_nat ? 1 : 0

  project = var.project_id
  name    = "${var.name}-${var.environment}-nat"
  router  = google_compute_router.main[0].name
  region  = var.region

  nat_ip_allocate_option             = var.nat_ip_allocate_option
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# -----------------------------------------------------------------------------
# Firewall Rules
# -----------------------------------------------------------------------------

resource "google_compute_firewall" "rules" {
  for_each = var.firewall_rules

  project     = var.project_id
  name        = "${var.name}-${each.key}-${var.environment}"
  network     = google_compute_network.main.id
  description = each.value.description
  direction   = each.value.direction
  priority    = each.value.priority

  source_ranges = each.value.direction == "INGRESS" ? each.value.source_ranges : null
  target_tags   = each.value.target_tags

  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = each.value.deny
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }
}

# Default firewall rules
resource "google_compute_firewall" "allow_internal" {
  project     = var.project_id
  name        = "${var.name}-allow-internal-${var.environment}"
  network     = google_compute_network.main.id
  description = "Allow internal traffic"
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = [for s in google_compute_subnetwork.subnets : s.ip_cidr_range]

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "allow_ssh_iap" {
  project     = var.project_id
  name        = "${var.name}-allow-ssh-iap-${var.environment}"
  network     = google_compute_network.main.id
  description = "Allow SSH via IAP"
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = ["35.235.240.0/20"] # IAP source range

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "network_id" {
  description = "VPC network ID"
  value       = google_compute_network.main.id
}

output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.main.name
}

output "network_self_link" {
  description = "VPC network self link"
  value       = google_compute_network.main.self_link
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.id }
}

output "subnet_self_links" {
  description = "Map of subnet names to self links"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.self_link }
}

output "subnet_regions" {
  description = "Map of subnet names to regions"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.region }
}

output "router_id" {
  description = "Cloud Router ID"
  value       = var.enable_nat ? google_compute_router.main[0].id : null
}

output "nat_id" {
  description = "Cloud NAT ID"
  value       = var.enable_nat ? google_compute_router_nat.main[0].id : null
}
