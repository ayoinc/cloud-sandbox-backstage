locals {
  network_available = var.enable_networking || var.existing_network != null
  network_id        = var.enable_networking ? google_compute_network.this[0].id : try(var.existing_network.network_id, null)

  public_subnet_ids  = var.enable_networking ? google_compute_subnetwork.public[*].id : try(var.existing_network.public_subnet_ids, [])
  private_subnet_ids = var.enable_networking ? google_compute_subnetwork.private[*].id : try(var.existing_network.private_subnet_ids, [])

  network_required_message = "This component needs a network: set enable_networking = true or pass existing_network."

  # The network range is cut into 16 equal blocks.
  public_subnet_cidrs  = [for index in range(2) : cidrsubnet(var.network_cidr, 4, index)]
  private_subnet_cidrs = [for index in range(2) : cidrsubnet(var.network_cidr, 4, index + 8)]

  # The last quarter of a created network is reserved for private services
  # access. In an existing network Google picks a free /20.
  private_services_cidr = cidrsubnet(var.network_cidr, 2, 3)
}

resource "google_compute_network" "this" {
  count = var.enable_networking ? 1 : 0

  project                 = var.project_id
  name                    = var.name_prefix
  description             = "Network of the ${var.name_prefix} ${var.environment} stack"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  depends_on = [time_sleep.api_propagation]
}

# Subnets are regional in Google Cloud: each one spans every zone of the
# region. Instances in the public subnets may have external addresses.
resource "google_compute_subnetwork" "public" {
  count = var.enable_networking ? 2 : 0

  project                  = var.project_id
  name                     = "${var.name_prefix}-public-${count.index + 1}"
  description              = "Public subnet ${count.index + 1}"
  region                   = var.region
  network                  = google_compute_network.this[0].id
  ip_cidr_range            = local.public_subnet_cidrs[count.index]
  private_ip_google_access = true

  dynamic "log_config" {
    for_each = var.require_flow_logs ? [1] : []

    content {
      aggregation_interval = "INTERVAL_10_MIN"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

# Instances in the private subnets have no external addresses and reach the
# internet through Cloud NAT.
resource "google_compute_subnetwork" "private" {
  count = var.enable_networking ? 2 : 0

  project                  = var.project_id
  name                     = "${var.name_prefix}-private-${count.index + 1}"
  description              = "Private subnet ${count.index + 1}"
  region                   = var.region
  network                  = google_compute_network.this[0].id
  ip_cidr_range            = local.private_subnet_cidrs[count.index]
  private_ip_google_access = true

  dynamic "log_config" {
    for_each = var.require_flow_logs ? [1] : []

    content {
      aggregation_interval = "INTERVAL_10_MIN"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

resource "google_compute_router" "this" {
  count = var.enable_networking ? 1 : 0

  project     = var.project_id
  name        = "${var.name_prefix}-router"
  description = "Router of the Cloud NAT gateway"
  region      = var.region
  network     = google_compute_network.this[0].id
}

# Cloud NAT is one regional, zone-redundant gateway that is billed per
# gateway, so there is nothing to multiply per zone.
resource "google_compute_router_nat" "this" {
  count = var.enable_networking ? 1 : 0

  project                            = var.project_id
  name                               = "${var.name_prefix}-nat"
  region                             = var.region
  router                             = google_compute_router.this[0].name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  # All ranges include the pod ranges that GKE adds to a private subnet.
  dynamic "subnetwork" {
    for_each = google_compute_subnetwork.private

    content {
      name                    = subnetwork.value.id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }

  log_config {
    enable = true
    filter = var.enable_monitoring ? "ALL" : "ERRORS_ONLY"
  }
}

# Flow logs of an existing network.
resource "google_network_management_vpc_flow_logs_config" "existing" {
  count = local.existing_network_flow_logs ? 1 : 0

  project                 = var.project_id
  location                = "global"
  vpc_flow_logs_config_id = "${var.name_prefix}-flow-logs"
  description             = "Flow logs of the network used by the ${var.name_prefix} stack"
  network                 = var.existing_network.network_id
  state                   = "ENABLED"
  aggregation_interval    = "INTERVAL_10_MIN"
  flow_sampling           = 0.5
  metadata                = "INCLUDE_ALL_METADATA"
  labels                  = local.labels

  depends_on = [time_sleep.api_propagation]
}

# -----------------------------------------------------------------------------
# Private services access
# -----------------------------------------------------------------------------

resource "google_compute_global_address" "private_services" {
  count = local.private_services_access ? 1 : 0

  project       = var.project_id
  name          = "${var.name_prefix}-private-services"
  description   = "Range for the private addresses of Cloud SQL and Memorystore"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = var.enable_networking ? cidrhost(local.private_services_cidr, 0) : null
  prefix_length = var.enable_networking ? tonumber(split("/", local.private_services_cidr)[1]) : 20
  network       = local.network_id

  depends_on = [time_sleep.api_propagation]

  lifecycle {
    precondition {
      condition     = local.network_available
      error_message = local.network_required_message
    }
  }
}

resource "google_service_networking_connection" "private_services" {
  count = local.private_services_access ? 1 : 0

  network                 = local.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services[0].name]

  # Google can refuse to delete the connection for a while after the last
  # database is gone. In a network of this stack the peering is then removed
  # directly so that the network can be destroyed; in an existing network the
  # connection is only ever deleted the regular way.
  deletion_policy = var.enable_networking ? "REMOVE_PEERING" : "DELETE"

  depends_on = [time_sleep.api_propagation]
}

# -----------------------------------------------------------------------------
# Private DNS zone (networking-foundation)
# -----------------------------------------------------------------------------

resource "google_dns_managed_zone" "private" {
  count = local.private_dns ? 1 : 0

  project     = var.project_id
  name        = "${var.name_prefix}-private"
  dns_name    = "${trimsuffix(coalesce(var.private_dns_domain, "${var.name_prefix}.internal"), ".")}."
  description = "Private zone of the ${var.name_prefix} network"
  visibility  = "private"
  labels      = local.labels

  private_visibility_config {
    networks {
      network_url = local.network_id
    }
  }

  depends_on = [time_sleep.api_propagation]

  lifecycle {
    precondition {
      condition     = local.network_available
      error_message = local.network_required_message
    }
  }
}
