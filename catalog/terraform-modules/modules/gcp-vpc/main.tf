/**
 * GCP VPC Module
 * 
 * Creates a production-ready VPC with:
 * - Custom mode VPC network
 * - Multiple subnets across regions
 * - Cloud NAT for private subnet internet access
 * - Firewall rules
 * - VPC Flow Logs
 * - Private Google Access
 */

#------------------------------------------------------------------------------
# VPC Network
#------------------------------------------------------------------------------
resource "google_compute_network" "main" {
  name                            = "${var.name}-vpc"
  project                         = var.project_id
  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = var.delete_default_routes
  mtu                             = var.mtu
}

#------------------------------------------------------------------------------
# Subnets
#------------------------------------------------------------------------------
resource "google_compute_subnetwork" "public" {
  count = length(var.public_subnets)

  name                     = "${var.name}-public-${count.index + 1}"
  project                  = var.project_id
  region                   = var.public_subnets[count.index].region
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.public_subnets[count.index].cidr
  private_ip_google_access = true

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = var.flow_logs_interval
      flow_sampling        = var.flow_logs_sampling
      metadata             = var.flow_logs_metadata
    }
  }

  secondary_ip_range = [
    for range in lookup(var.public_subnets[count.index], "secondary_ranges", []) : {
      range_name    = range.name
      ip_cidr_range = range.cidr
    }
  ]
}

resource "google_compute_subnetwork" "private" {
  count = length(var.private_subnets)

  name                     = "${var.name}-private-${count.index + 1}"
  project                  = var.project_id
  region                   = var.private_subnets[count.index].region
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.private_subnets[count.index].cidr
  private_ip_google_access = true

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = var.flow_logs_interval
      flow_sampling        = var.flow_logs_sampling
      metadata             = var.flow_logs_metadata
    }
  }

  secondary_ip_range = [
    for range in lookup(var.private_subnets[count.index], "secondary_ranges", []) : {
      range_name    = range.name
      ip_cidr_range = range.cidr
    }
  ]
}

#------------------------------------------------------------------------------
# Cloud Router (for Cloud NAT)
#------------------------------------------------------------------------------
resource "google_compute_router" "main" {
  count = var.enable_nat ? 1 : 0

  name    = "${var.name}-router"
  project = var.project_id
  region  = var.nat_region
  network = google_compute_network.main.id

  bgp {
    asn = var.router_asn
  }
}

#------------------------------------------------------------------------------
# Cloud NAT
#------------------------------------------------------------------------------
resource "google_compute_router_nat" "main" {
  count = var.enable_nat ? 1 : 0

  name                               = "${var.name}-nat"
  project                            = var.project_id
  region                             = var.nat_region
  router                             = google_compute_router.main[0].name
  nat_ip_allocate_option             = var.nat_ip_allocate_option
  source_subnetwork_ip_ranges_to_nat = var.nat_source_ranges

  dynamic "subnetwork" {
    for_each = var.nat_source_ranges == "LIST_OF_SUBNETWORKS" ? google_compute_subnetwork.private : []
    content {
      name                    = subnetwork.value.id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }

  log_config {
    enable = var.enable_nat_logs
    filter = var.nat_log_filter
  }

  min_ports_per_vm                    = var.nat_min_ports_per_vm
  max_ports_per_vm                    = var.nat_max_ports_per_vm
  enable_endpoint_independent_mapping = var.nat_enable_endpoint_independent_mapping
}

#------------------------------------------------------------------------------
# Firewall Rules
#------------------------------------------------------------------------------

# Allow internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.name}-allow-internal"
  project = var.project_id
  network = google_compute_network.main.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = concat(
    [for s in var.public_subnets : s.cidr],
    [for s in var.private_subnets : s.cidr]
  )

  priority = 1000
}

# Allow SSH from IAP
resource "google_compute_firewall" "allow_iap_ssh" {
  count = var.enable_iap_ssh ? 1 : 0

  name    = "${var.name}-allow-iap-ssh"
  project = var.project_id
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP's IP range
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-iap-ssh"]

  priority = 1000
}

# Allow HTTP/HTTPS from anywhere (for load balancers)
resource "google_compute_firewall" "allow_http_https" {
  count = var.enable_http_https ? 1 : 0

  name    = "${var.name}-allow-http-https"
  project = var.project_id
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]

  priority = 1000
}

# Allow health checks from Google
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.name}-allow-health-checks"
  project = var.project_id
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
  }

  # Google Cloud health check ranges
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["allow-health-checks"]

  priority = 1000
}

# Deny all ingress (default deny)
resource "google_compute_firewall" "deny_all_ingress" {
  count = var.enable_default_deny ? 1 : 0

  name    = "${var.name}-deny-all-ingress"
  project = var.project_id
  network = google_compute_network.main.id

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  priority      = 65534
}

#------------------------------------------------------------------------------
# Private Service Connection (for Cloud SQL, etc.)
#------------------------------------------------------------------------------
resource "google_compute_global_address" "private_service_range" {
  count = var.enable_private_service_access ? 1 : 0

  name          = "${var.name}-private-service-range"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_service_prefix_length
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_service" {
  count = var.enable_private_service_access ? 1 : 0

  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range[0].name]
}
