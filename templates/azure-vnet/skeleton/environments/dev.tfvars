# =============================================================================
# Development Environment Configuration
# =============================================================================
# Cost-optimized settings for development workloads
# - Smaller address space
# - NAT Gateway disabled to save costs
# - Simplified network topology
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "dev"
location    = "${{ values.location }}"
description = "${{ values.description }}"
owner       = "${{ values.owner }}"

# Network Configuration - Smaller /20 for dev
address_space = "10.0.0.0/20"

# Subnet CIDRs - Sized for development workloads
public_subnet_cidr   = "10.0.0.0/24"   # 254 hosts
private_subnet_cidr  = "10.0.1.0/24"   # 254 hosts
database_subnet_cidr = "10.0.2.0/26"   # 62 hosts
aks_subnet_cidr      = "10.0.4.0/22"   # 1022 hosts

# NAT Gateway - Disabled in dev to save costs
enable_nat_gateway = false
nat_idle_timeout   = 10

# Availability Zones - Single zone for dev
availability_zones = ["1"]

# DDoS Protection - Disabled in dev
enable_ddos_protection = false

# Tags
tags = {
  CostCenter  = "development"
  AutoShutdown = "true"
}
