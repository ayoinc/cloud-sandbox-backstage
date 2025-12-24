# =============================================================================
# GCP VPC - Staging Environment Configuration
# =============================================================================
# This file contains Jinja2 template variables that will be substituted
# by Backstage when the template is scaffolded.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables (from Backstage template)
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "staging"
region      = "${{ values.region }}"
description = "${{ values.description }}"
owner       = "${{ values.owner }}"

# -----------------------------------------------------------------------------
# VPC Configuration - Staging (production-like)
# -----------------------------------------------------------------------------
address_space = "${{ values.addressSpace }}"

# Subnet CIDRs
public_subnet_cidr   = "${{ values.publicSubnetCidr }}"
private_subnet_cidr  = "${{ values.privateSubnetCidr }}"
database_subnet_cidr = "${{ values.databaseSubnetCidr }}"
gke_subnet_cidr      = "${{ values.gkeSubnetCidr }}"

# GKE secondary ranges
gke_pods_cidr     = "10.100.0.0/16"
gke_services_cidr = "10.101.0.0/20"

# -----------------------------------------------------------------------------
# VPC Settings - Staging
# -----------------------------------------------------------------------------
routing_mode          = "REGIONAL"
delete_default_routes = false
mtu                   = 1460

# -----------------------------------------------------------------------------
# Flow Logs - Enabled in staging for monitoring
# -----------------------------------------------------------------------------
enable_flow_logs   = true
flow_logs_interval = "INTERVAL_5_SEC"
flow_logs_sampling = 0.5
flow_logs_metadata = "INCLUDE_ALL_METADATA"

# -----------------------------------------------------------------------------
# Cloud Router
# -----------------------------------------------------------------------------
router_asn = 64514

# -----------------------------------------------------------------------------
# Cloud NAT - Enabled in staging
# -----------------------------------------------------------------------------
enable_nat                              = true
nat_ip_allocate_option                  = "AUTO_ONLY"
nat_source_subnetwork_ip_ranges         = "ALL_SUBNETWORKS_ALL_IP_RANGES"
nat_min_ports_per_vm                    = 64
nat_max_ports_per_vm                    = 0
nat_enable_endpoint_independent_mapping = false
nat_tcp_established_idle_timeout        = 1200
nat_tcp_transitory_idle_timeout         = 30
nat_udp_idle_timeout                    = 30
nat_log_enable                          = true
nat_log_filter                          = "ERRORS_ONLY"

# -----------------------------------------------------------------------------
# Firewall Rules - Staging
# -----------------------------------------------------------------------------
enable_http_firewall     = true
enable_deny_all_firewall = false

# -----------------------------------------------------------------------------
# Private Service Access - Enabled for database connectivity
# -----------------------------------------------------------------------------
enable_private_service_access        = true
private_service_access_prefix_length = 16

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------
labels = {
  cost-center = "staging"
  team        = "${{ values.owner }}"
}
