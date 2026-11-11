# -----------------------------------------------------------------------------
# Virtual network: VPC network with a public and a private subnet
# -----------------------------------------------------------------------------

variable "network_cidr" {
  description = "Address range of the VPC network. Subnets are /4 slices of it, so it can be at most a /24."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrsubnet(var.network_cidr, 8, 0))
    error_message = "network_cidr must be a valid IPv4 CIDR block with a prefix of /24 or shorter."
  }
}

variable "enable_nat_gateway" {
  description = "Give resources without an external IP address outbound internet access through Cloud NAT."
  type        = bool
  default     = true
}

resource "google_project_service" "compute" {
  project            = local.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_network" "this" {
  project                 = local.project_id
  name                    = module.naming.standard["vpc"]
  auto_create_subnetworks = false

  depends_on = [google_project_service.compute]
}

resource "google_compute_subnetwork" "public" {
  project       = local.project_id
  name          = "${module.naming.standard["vpc"]}-public"
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = cidrsubnet(var.network_cidr, 4, 0)

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "private" {
  project       = local.project_id
  name          = "${module.naming.standard["vpc"]}-private"
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = cidrsubnet(var.network_cidr, 4, 8)

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  project = local.project_id
  name    = module.naming.standard["vpc"]
  region  = var.region
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  project                            = local.project_id
  name                               = module.naming.standard["vpc"]
  region                             = var.region
  router                             = google_compute_router.this[0].name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "internal" {
  project     = local.project_id
  name        = "${module.naming.standard["vpc"]}-allow-internal"
  network     = google_compute_network.this.id
  description = "Traffic between resources inside the network"
  direction   = "INGRESS"

  source_ranges = [var.network_cidr]

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

output "network_id" {
  description = "ID of the VPC network."
  value       = google_compute_network.this.id
}

output "public_subnet_id" {
  description = "ID of the public subnet."
  value       = google_compute_subnetwork.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet."
  value       = google_compute_subnetwork.private.id
}
