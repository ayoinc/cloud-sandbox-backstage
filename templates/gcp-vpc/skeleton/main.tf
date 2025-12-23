terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  
  backend "gcs" {
    # Configure your backend
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.region
}

locals {
  common_labels = {
    project     = var.name
    environment = var.environment
    managed-by  = "terraform"
    owner       = replace("${{ values.owner }}", "/", "-")
  }
}

# VPC Network
resource "google_compute_network" "main" {
  name                            = "${var.name}-${var.environment}-vpc"
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = false
}

# Public Subnet
resource "google_compute_subnetwork" "public" {
  name          = "${var.name}-${var.environment}-public"
  ip_cidr_range = cidrsubnet(var.cidr_range, 8, 1)
  region        = var.region
  network       = google_compute_network.main.id
  
  private_ip_google_access = true
  
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Private Subnet
resource "google_compute_subnetwork" "private" {
  name          = "${var.name}-${var.environment}-private"
  ip_cidr_range = cidrsubnet(var.cidr_range, 8, 2)
  region        = var.region
  network       = google_compute_network.main.id
  
  private_ip_google_access = true
  
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# GKE Subnet (larger for pod IPs)
resource "google_compute_subnetwork" "gke" {
  name          = "${var.name}-${var.environment}-gke"
  ip_cidr_range = cidrsubnet(var.cidr_range, 4, 1)
  region        = var.region
  network       = google_compute_network.main.id
  
  private_ip_google_access = true
  
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.100.0.0/16"
  }
  
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.101.0.0/20"
  }
}

# Cloud Router for NAT
resource "google_compute_router" "main" {
  name    = "${var.name}-${var.environment}-router"
  region  = var.region
  network = google_compute_network.main.id
  
  bgp {
    asn = 64514
  }
}

# Cloud NAT for outbound connectivity
resource "google_compute_router_nat" "main" {
  name                               = "${var.name}-${var.environment}-nat"
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall - Allow internal traffic
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.name}-${var.environment}-allow-internal"
  network = google_compute_network.main.name
  
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
  
  source_ranges = [var.cidr_range]
}

# Firewall - Allow SSH from IAP
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.name}-${var.environment}-allow-iap-ssh"
  network = google_compute_network.main.name
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["35.235.240.0/20"]  # IAP IP range
}

# Firewall - Allow HTTP/HTTPS
resource "google_compute_firewall" "allow_http" {
  name    = "${var.name}-${var.environment}-allow-http"
  network = google_compute_network.main.name
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}

# Firewall - Deny all ingress (low priority)
resource "google_compute_firewall" "deny_all" {
  name     = "${var.name}-${var.environment}-deny-all"
  network  = google_compute_network.main.name
  priority = 65534
  
  deny {
    protocol = "all"
  }
  
  source_ranges = ["0.0.0.0/0"]
}
