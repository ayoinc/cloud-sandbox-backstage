# =============================================================================
# GCP VPC Module - Main Configuration
# =============================================================================
# Creates a complete VPC networking setup including:
# - VPC Network
# - Public, Private, Database, and GKE Subnets
# - Cloud Router and Cloud NAT
# - Firewall rules
# =============================================================================

locals {
  # Naming convention: {resource_type}-{name}-{environment}
  vpc_name             = "vpc-${var.name}-${var.environment}"
  router_name          = "router-${var.name}-${var.environment}"
  nat_name             = "nat-${var.name}-${var.environment}"
  public_subnet_name   = "subnet-${var.name}-public-${var.environment}"
  private_subnet_name  = "subnet-${var.name}-private-${var.environment}"
  database_subnet_name = "subnet-${var.name}-database-${var.environment}"
  gke_subnet_name      = "subnet-${var.name}-gke-${var.environment}"

  # Common labels for all resources
  common_labels = merge(
    {
      project     = var.name
      environment = var.environment
      managed-by  = "terraform"
      owner       = replace(var.owner, "/", "-")
      description = substr(replace(var.description, " ", "-"), 0, 63)
    },
    var.labels
  )
}

# =============================================================================
# VPC Network
# =============================================================================
resource "google_compute_network" "main" {
  name                            = local.vpc_name
  description                     = var.description
  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = var.delete_default_routes
  mtu                             = var.mtu
}

# =============================================================================
# Subnets
# =============================================================================

# Public Subnet
resource "google_compute_subnetwork" "public" {
  name          = local.public_subnet_name
  description   = "Public subnet for internet-facing resources"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  private_ip_google_access = true
  stack_type               = "IPV4_ONLY"

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = var.flow_logs_interval
      flow_sampling        = var.flow_logs_sampling
      metadata             = var.flow_logs_metadata
    }
  }
}

# Private Subnet
resource "google_compute_subnetwork" "private" {
  name          = local.private_subnet_name
  description   = "Private subnet for internal resources"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  private_ip_google_access = true
  stack_type               = "IPV4_ONLY"

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = var.flow_logs_interval
      flow_sampling        = var.flow_logs_sampling
      metadata             = var.flow_logs_metadata
    }
  }
}

# Database Subnet
resource "google_compute_subnetwork" "database" {
  name          = local.database_subnet_name
  description   = "Database subnet for Cloud SQL and data stores"
  ip_cidr_range = var.database_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  private_ip_google_access = true
  stack_type               = "IPV4_ONLY"

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = var.flow_logs_interval
      flow_sampling        = var.flow_logs_sampling
      metadata             = var.flow_logs_metadata
    }
  }
}

# GKE Subnet with secondary ranges for pods and services
resource "google_compute_subnetwork" "gke" {
  name          = local.gke_subnet_name
  description   = "GKE subnet with pod and service secondary ranges"
  ip_cidr_range = var.gke_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  private_ip_google_access = true
  stack_type               = "IPV4_ONLY"

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.gke_pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.gke_services_cidr
  }

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = var.flow_logs_interval
      flow_sampling        = var.flow_logs_sampling
      metadata             = var.flow_logs_metadata
    }
  }
}

# =============================================================================
# Cloud Router
# =============================================================================
resource "google_compute_router" "main" {
  name        = local.router_name
  description = "Cloud Router for ${var.name} VPC"
  region      = var.region
  network     = google_compute_network.main.id

  bgp {
    asn               = var.router_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

# =============================================================================
# Cloud NAT
# =============================================================================
resource "google_compute_router_nat" "main" {
  count = var.enable_nat ? 1 : 0

  name                               = local.nat_name
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = var.nat_ip_allocate_option
  source_subnetwork_ip_ranges_to_nat = var.nat_source_subnetwork_ip_ranges

  # Timeout configurations
  min_ports_per_vm                    = var.nat_min_ports_per_vm
  max_ports_per_vm                    = var.nat_max_ports_per_vm
  enable_endpoint_independent_mapping = var.nat_enable_endpoint_independent_mapping
  tcp_established_idle_timeout_sec    = var.nat_tcp_established_idle_timeout
  tcp_transitory_idle_timeout_sec     = var.nat_tcp_transitory_idle_timeout
  udp_idle_timeout_sec                = var.nat_udp_idle_timeout

  log_config {
    enable = var.nat_log_enable
    filter = var.nat_log_filter
  }
}

# =============================================================================
# Firewall Rules
# =============================================================================

# Allow internal traffic within VPC
resource "google_compute_firewall" "allow_internal" {
  name        = "fw-${var.name}-allow-internal-${var.environment}"
  description = "Allow internal traffic within VPC"
  network     = google_compute_network.main.name
  priority    = 1000
  direction   = "INGRESS"

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

  source_ranges = [var.address_space]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow SSH from IAP (Identity-Aware Proxy)
resource "google_compute_firewall" "allow_iap_ssh" {
  name        = "fw-${var.name}-allow-iap-ssh-${var.environment}"
  description = "Allow SSH access from IAP"
  network     = google_compute_network.main.name
  priority    = 1000
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP IP range
  source_ranges = ["35.235.240.0/20"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow HTTP/HTTPS for tagged instances
resource "google_compute_firewall" "allow_http_https" {
  count = var.enable_http_firewall ? 1 : 0

  name        = "fw-${var.name}-allow-http-https-${var.environment}"
  description = "Allow HTTP/HTTPS from internet to tagged instances"
  network     = google_compute_network.main.name
  priority    = 1000
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow health checks from GCP load balancers
resource "google_compute_firewall" "allow_health_checks" {
  name        = "fw-${var.name}-allow-health-checks-${var.environment}"
  description = "Allow health checks from GCP load balancers"
  network     = google_compute_network.main.name
  priority    = 1000
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
  }

  # GCP health check IP ranges
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
    "209.85.152.0/22",
    "209.85.204.0/22"
  ]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Deny all ingress (low priority catch-all)
resource "google_compute_firewall" "deny_all_ingress" {
  count = var.enable_deny_all_firewall ? 1 : 0

  name        = "fw-${var.name}-deny-all-ingress-${var.environment}"
  description = "Deny all ingress traffic (catch-all rule)"
  network     = google_compute_network.main.name
  priority    = 65534
  direction   = "INGRESS"

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# =============================================================================
# Private Service Access (for Cloud SQL, Memorystore, etc.)
# =============================================================================
resource "google_compute_global_address" "private_service_access" {
  count = var.enable_private_service_access ? 1 : 0

  name          = "psa-${var.name}-${var.environment}"
  description   = "Private Service Access for ${var.name}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_service_access_prefix_length
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_service_access" {
  count = var.enable_private_service_access ? 1 : 0

  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access[0].name]
}
