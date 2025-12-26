# -----------------------------------------------------------------------------
# GCP Network Module - Main Resources
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_id}-${var.environment}"
  common_labels = merge(var.tags, {
    project     = var.project_id
    environment = var.environment
    managed_by  = "terraform"
  })

  # Flatten subnet configurations for iteration
  subnets = {
    public = {
      cidr             = var.subnet_cidrs.public
      purpose          = "public"
      secondary_ranges = {}
    }
    private = {
      cidr    = var.subnet_cidrs.private
      purpose = "private"
      secondary_ranges = var.enable_gke_secondary_ranges ? {
        pods     = var.secondary_ranges.pods
        services = var.secondary_ranges.services
      } : {}
    }
    database = {
      cidr             = var.subnet_cidrs.database
      purpose          = "database"
      secondary_ranges = {}
    }
  }
}

# -----------------------------------------------------------------------------
# VPC Network
# -----------------------------------------------------------------------------

resource "google_compute_network" "main" {
  name                            = "${var.network_name}-${var.environment}-vpc"
  project                         = var.project_id
  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = var.delete_default_routes

  description = "VPC network for ${var.project_id} ${var.environment} environment"
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------

resource "google_compute_subnetwork" "public" {
  name                     = "${var.network_name}-${var.environment}-public-subnet"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.subnet_cidrs.public
  private_ip_google_access = var.enable_private_google_access

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  description = "Public subnet for ${var.project_id} ${var.environment}"
}

resource "google_compute_subnetwork" "private" {
  name                     = "${var.network_name}-${var.environment}-private-subnet"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.subnet_cidrs.private
  private_ip_google_access = var.enable_private_google_access

  # Secondary IP ranges for GKE pods and services
  dynamic "secondary_ip_range" {
    for_each = var.enable_gke_secondary_ranges ? [1] : []
    content {
      range_name    = "${var.network_name}-${var.environment}-pods"
      ip_cidr_range = var.secondary_ranges.pods
    }
  }

  dynamic "secondary_ip_range" {
    for_each = var.enable_gke_secondary_ranges ? [1] : []
    content {
      range_name    = "${var.network_name}-${var.environment}-services"
      ip_cidr_range = var.secondary_ranges.services
    }
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  description = "Private subnet for ${var.project_id} ${var.environment}"
}

resource "google_compute_subnetwork" "database" {
  name                     = "${var.network_name}-${var.environment}-database-subnet"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.subnet_cidrs.database
  private_ip_google_access = var.enable_private_google_access

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  description = "Database subnet for ${var.project_id} ${var.environment}"
}

# -----------------------------------------------------------------------------
# Cloud Router (required for Cloud NAT)
# -----------------------------------------------------------------------------

resource "google_compute_router" "main" {
  count = var.enable_nat ? 1 : 0

  name    = "${var.network_name}-${var.environment}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.main.id

  bgp {
    asn               = var.router_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

    dynamic "advertised_ip_ranges" {
      for_each = var.router_advertised_ip_ranges
      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description
      }
    }
  }

  description = "Cloud Router for ${var.project_id} ${var.environment}"
}

# -----------------------------------------------------------------------------
# Cloud NAT
# -----------------------------------------------------------------------------

resource "google_compute_router_nat" "main" {
  count = var.enable_nat ? 1 : 0

  name                               = "${var.network_name}-${var.environment}-nat"
  project                            = var.project_id
  region                             = var.region
  router                             = google_compute_router.main[0].name
  nat_ip_allocate_option             = var.nat_ip_allocate_option
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  # NAT for private subnet
  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  # NAT for database subnet
  subnetwork {
    name                    = google_compute_subnetwork.database.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  # External IPs for NAT (if using manual allocation)
  nat_ips = var.nat_ip_allocate_option == "MANUAL_ONLY" ? google_compute_address.nat[*].self_link : null

  min_ports_per_vm                    = var.nat_min_ports_per_vm
  max_ports_per_vm                    = var.nat_max_ports_per_vm
  enable_dynamic_port_allocation      = var.enable_dynamic_port_allocation
  enable_endpoint_independent_mapping = var.enable_endpoint_independent_mapping
  icmp_idle_timeout_sec               = var.nat_icmp_idle_timeout_sec
  tcp_established_idle_timeout_sec    = var.nat_tcp_established_idle_timeout_sec
  tcp_transitory_idle_timeout_sec     = var.nat_tcp_transitory_idle_timeout_sec
  udp_idle_timeout_sec                = var.nat_udp_idle_timeout_sec

  log_config {
    enable = true
    filter = var.nat_log_filter
  }
}

# External IP addresses for NAT (when using manual allocation)
resource "google_compute_address" "nat" {
  count = var.enable_nat && var.nat_ip_allocate_option == "MANUAL_ONLY" ? var.nat_ip_count : 0

  name         = "${var.network_name}-${var.environment}-nat-ip-${count.index + 1}"
  project      = var.project_id
  region       = var.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"

  description = "External IP for Cloud NAT ${count.index + 1}"

  labels = local.common_labels
}

# -----------------------------------------------------------------------------
# Firewall Rules
# -----------------------------------------------------------------------------

# Allow internal traffic within VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network_name}-${var.environment}-allow-internal"
  project = var.project_id
  network = google_compute_network.main.name

  priority    = 1000
  direction   = "INGRESS"
  description = "Allow internal traffic between all instances in the VPC"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.subnet_cidrs.public,
    var.subnet_cidrs.private,
    var.subnet_cidrs.database
  ]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow SSH from specified ranges (typically bastion or IAP)
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.network_name}-${var.environment}-allow-ssh"
  project = var.project_id
  network = google_compute_network.main.name

  priority    = 1100
  direction   = "INGRESS"
  description = "Allow SSH access from specified source ranges"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = ["allow-ssh"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow HTTP traffic
resource "google_compute_firewall" "allow_http" {
  name    = "${var.network_name}-${var.environment}-allow-http"
  project = var.project_id
  network = google_compute_network.main.name

  priority    = 1200
  direction   = "INGRESS"
  description = "Allow HTTP traffic from internet"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = var.http_source_ranges
  target_tags   = ["allow-http", "http-server"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow HTTPS traffic
resource "google_compute_firewall" "allow_https" {
  name    = "${var.network_name}-${var.environment}-allow-https"
  project = var.project_id
  network = google_compute_network.main.name

  priority    = 1300
  direction   = "INGRESS"
  description = "Allow HTTPS traffic from internet"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = var.https_source_ranges
  target_tags   = ["allow-https", "https-server"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow health check traffic from Google Cloud health checkers
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.network_name}-${var.environment}-allow-health-checks"
  project = var.project_id
  network = google_compute_network.main.name

  priority    = 1400
  direction   = "INGRESS"
  description = "Allow health check traffic from Google Cloud"

  allow {
    protocol = "tcp"
  }

  # Google Cloud health check IP ranges
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow IAP (Identity-Aware Proxy) for secure access
resource "google_compute_firewall" "allow_iap" {
  count = var.enable_iap_access ? 1 : 0

  name    = "${var.network_name}-${var.environment}-allow-iap"
  project = var.project_id
  network = google_compute_network.main.name

  priority    = 1500
  direction   = "INGRESS"
  description = "Allow IAP tunnel access for SSH and RDP"

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  # Google Cloud IAP IP range
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-iap"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Deny all other ingress traffic (low priority catch-all)
resource "google_compute_firewall" "deny_all_ingress" {
  name    = "${var.network_name}-${var.environment}-deny-all-ingress"
  project = var.project_id
  network = google_compute_network.main.name

  priority    = 65534
  direction   = "INGRESS"
  description = "Deny all other ingress traffic"

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# -----------------------------------------------------------------------------
# Private Service Access (for Cloud SQL, Memorystore, etc.)
# -----------------------------------------------------------------------------

resource "google_compute_global_address" "private_service_access" {
  count = var.enable_private_service_access ? 1 : 0

  name          = "${var.network_name}-${var.environment}-psa-range"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_service_access_prefix_length
  network       = google_compute_network.main.id
  address       = var.private_service_access_address

  description = "Private Service Access IP range for ${var.project_id} ${var.environment}"
}

resource "google_service_networking_connection" "private_service_access" {
  count = var.enable_private_service_access ? 1 : 0

  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access[0].name]

  deletion_policy = "ABANDON"
}

# Export custom routes to peered networks (useful for VPN/Interconnect)
resource "google_compute_network_peering_routes_config" "private_service_access" {
  count = var.enable_private_service_access ? 1 : 0

  project = var.project_id
  peering = google_service_networking_connection.private_service_access[0].peering
  network = google_compute_network.main.name

  import_custom_routes = true
  export_custom_routes = true
}

# -----------------------------------------------------------------------------
# Private DNS Zone (Optional)
# -----------------------------------------------------------------------------

resource "google_dns_managed_zone" "private" {
  count = var.enable_private_dns ? 1 : 0

  name        = "${var.network_name}-${var.environment}-private-zone"
  project     = var.project_id
  dns_name    = var.private_dns_domain
  description = "Private DNS zone for ${var.project_id} ${var.environment}"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.main.id
    }
  }

  labels = local.common_labels
}

# DNS record for private service access (if using Cloud SQL, etc.)
resource "google_dns_record_set" "private_service_access" {
  count = var.enable_private_dns && var.enable_private_service_access ? 1 : 0

  name         = "*.${var.private_dns_domain}"
  project      = var.project_id
  managed_zone = google_dns_managed_zone.private[0].name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.private_service_access[0].address]
}

# -----------------------------------------------------------------------------
# Shared VPC (Optional)
# -----------------------------------------------------------------------------

resource "google_compute_shared_vpc_host_project" "host" {
  count = var.enable_shared_vpc_host ? 1 : 0

  project = var.project_id
}

# -----------------------------------------------------------------------------
# VPC Flow Logs Export (Optional - to Cloud Logging)
# -----------------------------------------------------------------------------

# Flow logs are enabled per-subnet via log_config blocks above
# Additional export to BigQuery or Cloud Storage can be configured via
# Cloud Logging sinks in a separate logging module
