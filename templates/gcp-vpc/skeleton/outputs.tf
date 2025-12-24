# =============================================================================
# GCP VPC - Root Outputs
# =============================================================================
# These outputs expose the VPC module outputs for use by other configurations.
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Network Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC Network ID"
  value       = module.vpc.vpc_id
}

output "vpc_name" {
  description = "VPC Network name"
  value       = module.vpc.vpc_name
}

output "vpc_self_link" {
  description = "VPC Network self link"
  value       = module.vpc.vpc_self_link
}

# -----------------------------------------------------------------------------
# Subnet Outputs
# -----------------------------------------------------------------------------

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = module.vpc.public_subnet_id
}

output "public_subnet_name" {
  description = "Public subnet name"
  value       = module.vpc.public_subnet_name
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = module.vpc.private_subnet_id
}

output "private_subnet_name" {
  description = "Private subnet name"
  value       = module.vpc.private_subnet_name
}

output "database_subnet_id" {
  description = "Database subnet ID"
  value       = module.vpc.database_subnet_id
}

output "database_subnet_name" {
  description = "Database subnet name"
  value       = module.vpc.database_subnet_name
}

output "gke_subnet_id" {
  description = "GKE subnet ID"
  value       = module.vpc.gke_subnet_id
}

output "gke_subnet_name" {
  description = "GKE subnet name"
  value       = module.vpc.gke_subnet_name
}

output "gke_pods_range_name" {
  description = "GKE pods secondary range name"
  value       = module.vpc.gke_pods_range_name
}

output "gke_services_range_name" {
  description = "GKE services secondary range name"
  value       = module.vpc.gke_services_range_name
}

# -----------------------------------------------------------------------------
# Subnet Maps
# -----------------------------------------------------------------------------

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = module.vpc.subnet_ids
}

output "subnet_names" {
  description = "Map of subnet types to names"
  value       = module.vpc.subnet_names
}

output "subnet_self_links" {
  description = "Map of subnet types to self links"
  value       = module.vpc.subnet_self_links
}

# -----------------------------------------------------------------------------
# Cloud Router Outputs
# -----------------------------------------------------------------------------

output "router_id" {
  description = "Cloud Router ID"
  value       = module.vpc.router_id
}

output "router_name" {
  description = "Cloud Router name"
  value       = module.vpc.router_name
}

# -----------------------------------------------------------------------------
# Cloud NAT Outputs
# -----------------------------------------------------------------------------

output "nat_id" {
  description = "Cloud NAT ID"
  value       = module.vpc.nat_id
}

output "nat_name" {
  description = "Cloud NAT name"
  value       = module.vpc.nat_name
}

# -----------------------------------------------------------------------------
# Private Service Access Outputs
# -----------------------------------------------------------------------------

output "private_service_access_address" {
  description = "Private Service Access address"
  value       = module.vpc.private_service_access_address
}

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------

output "vpc_info" {
  description = "Summary of VPC configuration"
  value       = module.vpc.vpc_info
}
