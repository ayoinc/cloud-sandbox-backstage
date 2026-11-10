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
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

# Network Configuration
address_space = "${{ values.addressSpace if (values.envName == 'staging' and values.addressSpace) else '10.1.0.0/18' }}"

# Subnets are carved out of the address space automatically: public, private
# and database each take 1/16 of it, AKS takes 1/4. Set any of these to
# override the layout:
# public_subnet_cidr   = "..."
# private_subnet_cidr  = "..."
# database_subnet_cidr = "..."
# aks_subnet_cidr      = "..."

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
