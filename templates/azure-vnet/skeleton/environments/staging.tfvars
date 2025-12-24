# =============================================================================
# Staging Environment Configuration
# =============================================================================
# Production-like settings for staging/testing workloads
# - Medium address space
# - NAT Gateway enabled for outbound connectivity
# - Multi-zone ready
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "staging"
location    = "${{ values.location }}"
description = "${{ values.description }}"
owner       = "${{ values.owner }}"

# Network Configuration - Medium /18 for staging
address_space = "10.1.0.0/18"

# Subnet CIDRs - Production-like sizing
public_subnet_cidr   = "10.1.0.0/22"   # 1022 hosts
private_subnet_cidr  = "10.1.4.0/22"   # 1022 hosts
database_subnet_cidr = "10.1.8.0/24"   # 254 hosts
aks_subnet_cidr      = "10.1.16.0/20"  # 4094 hosts

# NAT Gateway - Enabled for staging
enable_nat_gateway = true
nat_idle_timeout   = 10

# Availability Zones - Multiple zones for staging
availability_zones = ["1", "2"]

# DDoS Protection - Disabled in staging (cost consideration)
enable_ddos_protection = false

# Tags
tags = {
  CostCenter = "staging"
  Testing    = "true"
}
