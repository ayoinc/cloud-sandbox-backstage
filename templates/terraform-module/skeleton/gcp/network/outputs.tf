# -----------------------------------------------------------------------------
# GCP Network Module - Outputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# VPC Network
# -----------------------------------------------------------------------------

output "network_id" {
  description = "VPC network ID"
  value       = google_compute_network.main.id
}

output "network_self_link" {
  description = "VPC network self link"
  value       = google_compute_network.main.self_link
}

output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.main.name
}

output "network_gateway_ipv4" {
  description = "VPC network gateway IPv4 address"
  value       = google_compute_network.main.gateway_ipv4
}

# -----------------------------------------------------------------------------
# Subnets - IDs
# -----------------------------------------------------------------------------

output "subnet_ids" {
  description = "Map of subnet IDs by type"
  value = {
    public   = google_compute_subnetwork.public.id
    private  = google_compute_subnetwork.private.id
    database = google_compute_subnetwork.database.id
  }
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = google_compute_subnetwork.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = google_compute_subnetwork.private.id
}

output "database_subnet_id" {
  description = "Database subnet ID"
  value       = google_compute_subnetwork.database.id
}

# -----------------------------------------------------------------------------
# Subnets - Self Links
# -----------------------------------------------------------------------------

output "subnet_self_links" {
  description = "Map of subnet self links by type"
  value = {
    public   = google_compute_subnetwork.public.self_link
    private  = google_compute_subnetwork.private.self_link
    database = google_compute_subnetwork.database.self_link
  }
}

output "public_subnet_self_link" {
  description = "Public subnet self link"
  value       = google_compute_subnetwork.public.self_link
}

output "private_subnet_self_link" {
  description = "Private subnet self link"
  value       = google_compute_subnetwork.private.self_link
}

output "database_subnet_self_link" {
  description = "Database subnet self link"
  value       = google_compute_subnetwork.database.self_link
}

# -----------------------------------------------------------------------------
# Subnets - Names
# -----------------------------------------------------------------------------

output "subnet_names" {
  description = "Map of subnet names by type"
  value = {
    public   = google_compute_subnetwork.public.name
    private  = google_compute_subnetwork.private.name
    database = google_compute_subnetwork.database.name
  }
}

# -----------------------------------------------------------------------------
# Subnets - CIDR Ranges
# -----------------------------------------------------------------------------

output "subnet_cidrs" {
  description = "Map of subnet CIDR ranges by type"
  value = {
    public   = google_compute_subnetwork.public.ip_cidr_range
    private  = google_compute_subnetwork.private.ip_cidr_range
    database = google_compute_subnetwork.database.ip_cidr_range
  }
}

# -----------------------------------------------------------------------------
# Secondary Ranges (for GKE)
# -----------------------------------------------------------------------------

output "gke_pods_range_name" {
  description = "Name of the secondary IP range for GKE pods"
  value       = var.enable_gke_secondary_ranges ? "${var.network_name}-${var.environment}-pods" : null
}

output "gke_services_range_name" {
  description = "Name of the secondary IP range for GKE services"
  value       = var.enable_gke_secondary_ranges ? "${var.network_name}-${var.environment}-services" : null
}

output "gke_secondary_ranges" {
  description = "GKE secondary IP ranges configuration"
  value = var.enable_gke_secondary_ranges ? {
    pods = {
      range_name    = "${var.network_name}-${var.environment}-pods"
      ip_cidr_range = var.secondary_ranges.pods
    }
    services = {
      range_name    = "${var.network_name}-${var.environment}-services"
      ip_cidr_range = var.secondary_ranges.services
    }
  } : null
}

# -----------------------------------------------------------------------------
# Cloud Router
# -----------------------------------------------------------------------------

output "router_id" {
  description = "Cloud Router ID"
  value       = var.enable_nat ? google_compute_router.main[0].id : null
}

output "router_name" {
  description = "Cloud Router name"
  value       = var.enable_nat ? google_compute_router.main[0].name : null
}

output "router_self_link" {
  description = "Cloud Router self link"
  value       = var.enable_nat ? google_compute_router.main[0].self_link : null
}

# -----------------------------------------------------------------------------
# Cloud NAT
# -----------------------------------------------------------------------------

output "nat_id" {
  description = "Cloud NAT ID"
  value       = var.enable_nat ? google_compute_router_nat.main[0].id : null
}

output "nat_name" {
  description = "Cloud NAT name"
  value       = var.enable_nat ? google_compute_router_nat.main[0].name : null
}

output "nat_ips" {
  description = "External IP addresses used by Cloud NAT"
  value       = var.enable_nat && var.nat_ip_allocate_option == "MANUAL_ONLY" ? google_compute_address.nat[*].address : null
}

output "nat_ip_self_links" {
  description = "Self links of external IPs used by Cloud NAT"
  value       = var.enable_nat && var.nat_ip_allocate_option == "MANUAL_ONLY" ? google_compute_address.nat[*].self_link : null
}

# -----------------------------------------------------------------------------
# Firewall Rules
# -----------------------------------------------------------------------------

output "firewall_rule_ids" {
  description = "Map of firewall rule IDs"
  value = {
    allow_internal      = google_compute_firewall.allow_internal.id
    allow_ssh           = google_compute_firewall.allow_ssh.id
    allow_http          = google_compute_firewall.allow_http.id
    allow_https         = google_compute_firewall.allow_https.id
    allow_health_checks = google_compute_firewall.allow_health_checks.id
    allow_iap           = var.enable_iap_access ? google_compute_firewall.allow_iap[0].id : null
    deny_all_ingress    = google_compute_firewall.deny_all_ingress.id
  }
}

output "firewall_rule_self_links" {
  description = "Map of firewall rule self links"
  value = {
    allow_internal      = google_compute_firewall.allow_internal.self_link
    allow_ssh           = google_compute_firewall.allow_ssh.self_link
    allow_http          = google_compute_firewall.allow_http.self_link
    allow_https         = google_compute_firewall.allow_https.self_link
    allow_health_checks = google_compute_firewall.allow_health_checks.self_link
    allow_iap           = var.enable_iap_access ? google_compute_firewall.allow_iap[0].self_link : null
    deny_all_ingress    = google_compute_firewall.deny_all_ingress.self_link
  }
}

# -----------------------------------------------------------------------------
# Private Service Access
# -----------------------------------------------------------------------------

output "private_service_access_address" {
  description = "Private Service Access IP address"
  value       = var.enable_private_service_access ? google_compute_global_address.private_service_access[0].address : null
}

output "private_service_access_range" {
  description = "Private Service Access IP range name"
  value       = var.enable_private_service_access ? google_compute_global_address.private_service_access[0].name : null
}

output "private_service_access_cidr" {
  description = "Private Service Access CIDR block"
  value       = var.enable_private_service_access ? "${google_compute_global_address.private_service_access[0].address}/${google_compute_global_address.private_service_access[0].prefix_length}" : null
}

output "private_service_connection_peering" {
  description = "Private Service Access VPC peering name"
  value       = var.enable_private_service_access ? google_service_networking_connection.private_service_access[0].peering : null
}

# -----------------------------------------------------------------------------
# Private DNS
# -----------------------------------------------------------------------------

output "private_dns_zone_id" {
  description = "Private DNS zone ID"
  value       = var.enable_private_dns ? google_dns_managed_zone.private[0].id : null
}

output "private_dns_zone_name" {
  description = "Private DNS zone name"
  value       = var.enable_private_dns ? google_dns_managed_zone.private[0].name : null
}

output "private_dns_name_servers" {
  description = "Private DNS zone name servers"
  value       = var.enable_private_dns ? google_dns_managed_zone.private[0].name_servers : null
}

# -----------------------------------------------------------------------------
# Computed Values for Downstream Modules
# -----------------------------------------------------------------------------

output "subnet_map" {
  description = "Complete map of subnet information for downstream modules"
  value = {
    public = {
      id              = google_compute_subnetwork.public.id
      self_link       = google_compute_subnetwork.public.self_link
      name            = google_compute_subnetwork.public.name
      cidr            = google_compute_subnetwork.public.ip_cidr_range
      region          = google_compute_subnetwork.public.region
      gateway_address = google_compute_subnetwork.public.gateway_address
    }
    private = {
      id              = google_compute_subnetwork.private.id
      self_link       = google_compute_subnetwork.private.self_link
      name            = google_compute_subnetwork.private.name
      cidr            = google_compute_subnetwork.private.ip_cidr_range
      region          = google_compute_subnetwork.private.region
      gateway_address = google_compute_subnetwork.private.gateway_address
      secondary_ranges = var.enable_gke_secondary_ranges ? {
        pods     = var.secondary_ranges.pods
        services = var.secondary_ranges.services
      } : {}
    }
    database = {
      id              = google_compute_subnetwork.database.id
      self_link       = google_compute_subnetwork.database.self_link
      name            = google_compute_subnetwork.database.name
      cidr            = google_compute_subnetwork.database.ip_cidr_range
      region          = google_compute_subnetwork.database.region
      gateway_address = google_compute_subnetwork.database.gateway_address
    }
  }
}

output "network_tags" {
  description = "Recommended network tags for instances"
  value = {
    allow_ssh    = "allow-ssh"
    allow_http   = "allow-http"
    allow_https  = "allow-https"
    allow_iap    = "allow-iap"
    http_server  = "http-server"
    https_server = "https-server"
  }
}
