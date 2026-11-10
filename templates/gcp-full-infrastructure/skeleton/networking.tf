# =============================================================================
# Networking: VPC network, subnets, Cloud NAT, firewall rules and private
# service access
# =============================================================================

locals {
  subnets = var.enable_networking ? { for subnet in var.subnets : subnet.name => subnet } : {}

  # One Cloud Router and Cloud NAT per region that has a subnet.
  nat_regions = var.enable_networking ? toset(concat([var.region], var.subnets[*].region)) : toset([])
}

resource "google_compute_network" "main" {
  count = var.enable_networking ? 1 : 0

  name                    = "${local.name_prefix}-vpc"
  description             = var.description != "" ? var.description : "VPC network of ${var.project_name} (${var.environment})"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  depends_on = [google_project_service.main]
}

resource "google_compute_subnetwork" "main" {
  for_each = local.subnets

  name                     = "${local.name_prefix}-${each.key}"
  network                  = google_compute_network.main[0].id
  region                   = each.value.region
  ip_cidr_range            = each.value.cidr
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "main" {
  for_each = local.nat_regions

  name    = "${local.name_prefix}-router-${each.value}"
  network = google_compute_network.main[0].id
  region  = each.value
}

# Outbound internet access for instances without a public address.
resource "google_compute_router_nat" "main" {
  for_each = local.nat_regions

  name                               = "${local.name_prefix}-nat-${each.value}"
  router                             = google_compute_router.main[each.value].name
  region                             = each.value
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Resources inside the VPC network range may reach each other on every port.
# trivy:ignore:AVD-GCP-0072
resource "google_compute_firewall" "allow_internal" {
  count = var.enable_networking ? 1 : 0

  name        = "${local.name_prefix}-allow-internal"
  description = "Allow traffic between resources inside the VPC network"
  network     = google_compute_network.main[0].name
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.network_cidr]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# SSH is only reachable through Identity-Aware Proxy TCP forwarding.
resource "google_compute_firewall" "allow_iap_ssh" {
  count = var.enable_networking ? 1 : 0

  name        = "${local.name_prefix}-allow-iap-ssh"
  description = "Allow SSH from Identity-Aware Proxy"
  network     = google_compute_network.main[0].name
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Health checks of Google Cloud load balancers and managed instance groups.
resource "google_compute_firewall" "allow_health_checks" {
  count = var.enable_networking ? 1 : 0

  name        = "${local.name_prefix}-allow-health-checks"
  description = "Allow Google Cloud health checks"
  network     = google_compute_network.main[0].name
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Range reserved for Google services (Cloud SQL, Memorystore) and the peering
# that connects them to the network.
resource "google_compute_global_address" "private_service_access" {
  count = local.needs_private_service_access ? 1 : 0

  name          = "${local.name_prefix}-google-services"
  description   = "Range reserved for Google services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_service_access_prefix_length
  network       = local.network_id
  labels        = local.labels

  depends_on = [google_project_service.main]
}

resource "google_service_networking_connection" "private_service_access" {
  count = local.needs_private_service_access ? 1 : 0

  network                 = local.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access[0].name]
}
