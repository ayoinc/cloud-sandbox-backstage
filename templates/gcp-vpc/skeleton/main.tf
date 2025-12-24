# =============================================================================
# GCP VPC - Root Configuration
# =============================================================================
# This is the root module that calls the reusable VPC module.
# Environment-specific values are provided via tfvars files.
# =============================================================================

# =============================================================================
# Module: VPC
# =============================================================================
module "vpc" {
  source = "./modules/vpc"

  # Required variables
  name        = var.name
  environment = var.environment
  region      = var.region

  # Optional metadata
  description = var.description
  owner       = var.owner
  labels      = var.labels

  # VPC configuration
  address_space         = var.address_space
  routing_mode          = var.routing_mode
  delete_default_routes = var.delete_default_routes
  mtu                   = var.mtu

  # Subnet CIDRs
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidr  = var.private_subnet_cidr
  database_subnet_cidr = var.database_subnet_cidr
  gke_subnet_cidr      = var.gke_subnet_cidr
  gke_pods_cidr        = var.gke_pods_cidr
  gke_services_cidr    = var.gke_services_cidr

  # Flow logs
  enable_flow_logs   = var.enable_flow_logs
  flow_logs_interval = var.flow_logs_interval
  flow_logs_sampling = var.flow_logs_sampling
  flow_logs_metadata = var.flow_logs_metadata

  # Cloud Router
  router_asn = var.router_asn

  # Cloud NAT
  enable_nat                              = var.enable_nat
  nat_ip_allocate_option                  = var.nat_ip_allocate_option
  nat_source_subnetwork_ip_ranges         = var.nat_source_subnetwork_ip_ranges
  nat_min_ports_per_vm                    = var.nat_min_ports_per_vm
  nat_max_ports_per_vm                    = var.nat_max_ports_per_vm
  nat_enable_endpoint_independent_mapping = var.nat_enable_endpoint_independent_mapping
  nat_tcp_established_idle_timeout        = var.nat_tcp_established_idle_timeout
  nat_tcp_transitory_idle_timeout         = var.nat_tcp_transitory_idle_timeout
  nat_udp_idle_timeout                    = var.nat_udp_idle_timeout
  nat_log_enable                          = var.nat_log_enable
  nat_log_filter                          = var.nat_log_filter

  # Firewall
  enable_http_firewall     = var.enable_http_firewall
  enable_deny_all_firewall = var.enable_deny_all_firewall

  # Private Service Access
  enable_private_service_access        = var.enable_private_service_access
  private_service_access_prefix_length = var.private_service_access_prefix_length
}
