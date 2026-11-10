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
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

# Network Configuration
address_space = "${{ values.addressSpace if (values.envName == 'dev' and values.addressSpace) else '10.0.0.0/20' }}"

# Subnets are carved out of the address space automatically: public, private
# and database each take 1/16 of it, AKS takes 1/4. Set any of these to
# override the layout:
# public_subnet_cidr   = "..."
# private_subnet_cidr  = "..."
# database_subnet_cidr = "..."
# aks_subnet_cidr      = "..."

# NAT Gateway - Disabled in dev to save costs
enable_nat_gateway = false
nat_idle_timeout   = 10

# Availability Zones - Single zone for dev
availability_zones = ["1"]

# DDoS Protection - Disabled in dev
enable_ddos_protection = false

# Tags
tags = {
  CostCenter   = "development"
  AutoShutdown = "true"
}
