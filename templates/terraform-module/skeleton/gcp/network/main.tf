locals {
  # Resource names are limited to 63 characters and service account IDs to 30,
  # so the project name is shortened before the environment is appended.
  name_prefix = "${trimsuffix(substr(var.project_name, 0, 16), "-")}-${var.environment}"

  labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })

  # Three equally sized subnets carved from the VPC range. The private subnet
  # is first because it is the one workloads attach to.
  subnets = {
    private  = cidrsubnet(var.network_cidr, var.subnet_newbits, 0)
    public   = cidrsubnet(var.network_cidr, var.subnet_newbits, 1)
    database = cidrsubnet(var.network_cidr, var.subnet_newbits, 2)
  }
  subnet_order = ["private", "public", "database"]

  pods_range_name     = "${local.name_prefix}-pods"
  services_range_name = "${local.name_prefix}-services"

  # Google front ends that proxy IAP TCP forwarding and load balancer health checks.
  iap_source_ranges          = ["35.235.240.0/20"]
  health_check_source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

# -----------------------------------------------------------------------------
# VPC and subnets
# -----------------------------------------------------------------------------

resource "google_compute_network" "main" {
  project                 = var.project_id
  name                    = "${local.name_prefix}-vpc"
  description             = "VPC for ${var.project_name} (${var.environment})"
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
}

resource "google_compute_subnetwork" "main" {
  for_each = local.subnets

  project                  = var.project_id
  region                   = var.region
  name                     = "${local.name_prefix}-${each.key}"
  description              = "${title(each.key)} subnet for ${var.project_name} (${var.environment})"
  network                  = google_compute_network.main.id
  ip_cidr_range            = each.value
  private_ip_google_access = true

  dynamic "secondary_ip_range" {
    for_each = each.key == "private" && var.enable_gke_secondary_ranges ? {
      (local.pods_range_name)     = var.gke_pods_cidr
      (local.services_range_name) = var.gke_services_cidr
    } : {}

    content {
      range_name    = secondary_ip_range.key
      ip_cidr_range = secondary_ip_range.value
    }
  }

  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []

    content {
      aggregation_interval = "INTERVAL_10_MIN"
      flow_sampling        = var.flow_log_sampling
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

# -----------------------------------------------------------------------------
# Outbound internet access for instances without external addresses
# -----------------------------------------------------------------------------

resource "google_compute_router" "main" {
  count = var.enable_nat ? 1 : 0

  project = var.project_id
  region  = var.region
  name    = "${local.name_prefix}-router"
  network = google_compute_network.main.id
}

resource "google_compute_address" "nat" {
  count = var.enable_nat ? var.nat_ip_count : 0

  project      = var.project_id
  region       = var.region
  name         = "${local.name_prefix}-nat-${count.index + 1}"
  description  = "Static egress address ${count.index + 1} for Cloud NAT"
  address_type = "EXTERNAL"
  labels       = local.labels
}

resource "google_compute_router_nat" "main" {
  count = var.enable_nat ? 1 : 0

  project = var.project_id
  region  = var.region
  name    = "${local.name_prefix}-nat"
  router  = google_compute_router.main[0].name

  nat_ip_allocate_option = var.nat_ip_count > 0 ? "MANUAL_ONLY" : "AUTO_ONLY"
  nat_ips                = var.nat_ip_count > 0 ? google_compute_address.nat[*].self_link : null

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = ["private", "database"]

    content {
      name                    = google_compute_subnetwork.main[subnetwork.value].id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# -----------------------------------------------------------------------------
# Firewall
# -----------------------------------------------------------------------------

resource "google_compute_firewall" "allow_internal" {
  project     = var.project_id
  name        = "${local.name_prefix}-allow-internal"
  description = "Allow traffic between addresses inside the VPC"
  network     = google_compute_network.main.name
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = concat(
    [var.network_cidr],
    var.enable_gke_secondary_ranges ? [var.gke_pods_cidr] : [],
  )

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

resource "google_compute_firewall" "allow_iap_ssh" {
  count = var.enable_iap_ssh ? 1 : 0

  project       = var.project_id
  name          = "${local.name_prefix}-allow-iap-ssh"
  description   = "Allow SSH through Identity-Aware Proxy TCP forwarding"
  network       = google_compute_network.main.name
  direction     = "INGRESS"
  priority      = 1000
  source_ranges = local.iap_source_ranges
  target_tags   = ["allow-iap-ssh"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "allow_health_checks" {
  project       = var.project_id
  name          = "${local.name_prefix}-allow-health-checks"
  description   = "Allow Google Cloud load balancer health check probes"
  network       = google_compute_network.main.name
  direction     = "INGRESS"
  priority      = 1000
  source_ranges = local.health_check_source_ranges
  target_tags   = ["allow-health-check"]

  allow {
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "allow_web" {
  count = length(var.web_source_ranges) > 0 ? 1 : 0

  project       = var.project_id
  name          = "${local.name_prefix}-allow-web"
  description   = "Allow HTTP and HTTPS from the configured source ranges"
  network       = google_compute_network.main.name
  direction     = "INGRESS"
  priority      = 1000
  source_ranges = var.web_source_ranges
  target_tags   = ["web"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

# The implied deny rule is not logged, so an explicit one records rejected connections.
resource "google_compute_firewall" "deny_all_ingress" {
  project       = var.project_id
  name          = "${local.name_prefix}-deny-all-ingress"
  description   = "Deny and log all ingress that no other rule allows"
  network       = google_compute_network.main.name
  direction     = "INGRESS"
  priority      = 65534
  source_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }

  log_config {
    metadata = "EXCLUDE_ALL_METADATA"
  }
}

# -----------------------------------------------------------------------------
# Private service access (Cloud SQL, Memorystore, Filestore)
# -----------------------------------------------------------------------------

resource "google_compute_global_address" "private_service_access" {
  count = var.enable_private_service_access ? 1 : 0

  project       = var.project_id
  name          = "${local.name_prefix}-psa"
  description   = "Address range reserved for Google managed services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_service_access_prefix_length
  network       = google_compute_network.main.id
  labels        = local.labels
}

resource "google_service_networking_connection" "private_service_access" {
  count = var.enable_private_service_access ? 1 : 0

  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access[0].name]
}

# -----------------------------------------------------------------------------
# Private DNS
# -----------------------------------------------------------------------------

resource "google_dns_managed_zone" "private" {
  count = var.enable_private_dns ? 1 : 0

  project     = var.project_id
  name        = "${local.name_prefix}-private"
  description = "Private zone for ${var.project_name} (${var.environment})"
  dns_name    = var.private_dns_domain
  visibility  = "private"
  labels      = local.labels

  private_visibility_config {
    networks {
      network_url = google_compute_network.main.id
    }
  }
}

# -----------------------------------------------------------------------------
# Shared VPC
# -----------------------------------------------------------------------------

resource "google_compute_shared_vpc_host_project" "main" {
  count = var.enable_shared_vpc_host ? 1 : 0

  project = var.project_id

  depends_on = [google_compute_network.main]
}
