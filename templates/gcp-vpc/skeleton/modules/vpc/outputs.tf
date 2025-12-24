# =============================================================================
# GCP VPC Module - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Network Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC Network ID"
  value       = google_compute_network.main.id
}

output "vpc_name" {
  description = "VPC Network name"
  value       = google_compute_network.main.name
}

output "vpc_self_link" {
  description = "VPC Network self link"
  value       = google_compute_network.main.self_link
}

output "vpc_gateway_ipv4" {
  description = "Gateway IPv4 address of the VPC"
  value       = google_compute_network.main.gateway_ipv4
}

# -----------------------------------------------------------------------------
# Subnet Outputs - Public
# -----------------------------------------------------------------------------

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = google_compute_subnetwork.public.id
}

output "public_subnet_name" {
  description = "Public subnet name"
  value       = google_compute_subnetwork.public.name
}

output "public_subnet_self_link" {
  description = "Public subnet self link"
  value       = google_compute_subnetwork.public.self_link
}

output "public_subnet_cidr" {
  description = "Public subnet CIDR block"
  value       = google_compute_subnetwork.public.ip_cidr_range
}

# -----------------------------------------------------------------------------
# Subnet Outputs - Private
# -----------------------------------------------------------------------------

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = google_compute_subnetwork.private.id
}

output "private_subnet_name" {
  description = "Private subnet name"
  value       = google_compute_subnetwork.private.name
}

output "private_subnet_self_link" {
  description = "Private subnet self link"
  value       = google_compute_subnetwork.private.self_link
}

output "private_subnet_cidr" {
  description = "Private subnet CIDR block"
  value       = google_compute_subnetwork.private.ip_cidr_range
}

# -----------------------------------------------------------------------------
# Subnet Outputs - Database
# -----------------------------------------------------------------------------

output "database_subnet_id" {
  description = "Database subnet ID"
  value       = google_compute_subnetwork.database.id
}

output "database_subnet_name" {
  description = "Database subnet name"
  value       = google_compute_subnetwork.database.name
}

output "database_subnet_self_link" {
  description = "Database subnet self link"
  value       = google_compute_subnetwork.database.self_link
}

output "database_subnet_cidr" {
  description = "Database subnet CIDR block"
  value       = google_compute_subnetwork.database.ip_cidr_range
}

# -----------------------------------------------------------------------------
# Subnet Outputs - GKE
# -----------------------------------------------------------------------------

output "gke_subnet_id" {
  description = "GKE subnet ID"
  value       = google_compute_subnetwork.gke.id
}

output "gke_subnet_name" {
  description = "GKE subnet name"
  value       = google_compute_subnetwork.gke.name
}

output "gke_subnet_self_link" {
  description = "GKE subnet self link"
  value       = google_compute_subnetwork.gke.self_link
}

output "gke_subnet_cidr" {
  description = "GKE subnet CIDR block"
  value       = google_compute_subnetwork.gke.ip_cidr_range
}

output "gke_pods_range_name" {
  description = "GKE pods secondary range name"
  value       = google_compute_subnetwork.gke.secondary_ip_range[0].range_name
}

output "gke_services_range_name" {
  description = "GKE services secondary range name"
  value       = google_compute_subnetwork.gke.secondary_ip_range[1].range_name
}

# -----------------------------------------------------------------------------
# Subnet ID Map
# -----------------------------------------------------------------------------

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value = {
    public   = google_compute_subnetwork.public.id
    private  = google_compute_subnetwork.private.id
    database = google_compute_subnetwork.database.id
    gke      = google_compute_subnetwork.gke.id
  }
}

output "subnet_names" {
  description = "Map of subnet types to names"
  value = {
    public   = google_compute_subnetwork.public.name
    private  = google_compute_subnetwork.private.name
    database = google_compute_subnetwork.database.name
    gke      = google_compute_subnetwork.gke.name
  }
}

output "subnet_self_links" {
  description = "Map of subnet types to self links"
  value = {
    public   = google_compute_subnetwork.public.self_link
    private  = google_compute_subnetwork.private.self_link
    database = google_compute_subnetwork.database.self_link
    gke      = google_compute_subnetwork.gke.self_link
  }
}

# -----------------------------------------------------------------------------
# Cloud Router Outputs
# -----------------------------------------------------------------------------

output "router_id" {
  description = "Cloud Router ID"
  value       = google_compute_router.main.id
}

output "router_name" {
  description = "Cloud Router name"
  value       = google_compute_router.main.name
}

output "router_self_link" {
  description = "Cloud Router self link"
  value       = google_compute_router.main.self_link
}

# -----------------------------------------------------------------------------
# Cloud NAT Outputs
# -----------------------------------------------------------------------------

output "nat_id" {
  description = "Cloud NAT ID (null if NAT is disabled)"
  value       = var.enable_nat ? google_compute_router_nat.main[0].id : null
}

output "nat_name" {
  description = "Cloud NAT name (null if NAT is disabled)"
  value       = var.enable_nat ? google_compute_router_nat.main[0].name : null
}

# -----------------------------------------------------------------------------
# Firewall Outputs
# -----------------------------------------------------------------------------

output "firewall_internal_id" {
  description = "Internal firewall rule ID"
  value       = google_compute_firewall.allow_internal.id
}

output "firewall_iap_ssh_id" {
  description = "IAP SSH firewall rule ID"
  value       = google_compute_firewall.allow_iap_ssh.id
}

output "firewall_http_https_id" {
  description = "HTTP/HTTPS firewall rule ID (null if disabled)"
  value       = var.enable_http_firewall ? google_compute_firewall.allow_http_https[0].id : null
}

output "firewall_health_checks_id" {
  description = "Health checks firewall rule ID"
  value       = google_compute_firewall.allow_health_checks.id
}

# -----------------------------------------------------------------------------
# Private Service Access Outputs
# -----------------------------------------------------------------------------

output "private_service_access_address" {
  description = "Private Service Access address (null if disabled)"
  value       = var.enable_private_service_access ? google_compute_global_address.private_service_access[0].address : null
}

output "private_service_access_name" {
  description = "Private Service Access name (null if disabled)"
  value       = var.enable_private_service_access ? google_compute_global_address.private_service_access[0].name : null
}

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------

output "vpc_info" {
  description = "Summary of VPC configuration"
  value = {
    name          = google_compute_network.main.name
    id            = google_compute_network.main.id
    self_link     = google_compute_network.main.self_link
    region        = var.region
    routing_mode  = var.routing_mode
    address_space = var.address_space

    subnets = {
      public = {
        name = google_compute_subnetwork.public.name
        cidr = google_compute_subnetwork.public.ip_cidr_range
      }
      private = {
        name = google_compute_subnetwork.private.name
        cidr = google_compute_subnetwork.private.ip_cidr_range
      }
      database = {
        name = google_compute_subnetwork.database.name
        cidr = google_compute_subnetwork.database.ip_cidr_range
      }
      gke = {
        name           = google_compute_subnetwork.gke.name
        cidr           = google_compute_subnetwork.gke.ip_cidr_range
        pods_range     = var.gke_pods_cidr
        services_range = var.gke_services_cidr
      }
    }

    router_name = google_compute_router.main.name
    nat_enabled = var.enable_nat
    nat_name    = var.enable_nat ? google_compute_router_nat.main[0].name : null

    flow_logs_enabled      = var.enable_flow_logs
    private_service_access = var.enable_private_service_access
  }
}
