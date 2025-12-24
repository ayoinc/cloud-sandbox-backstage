# =============================================================================
# Production Environment Configuration
# =============================================================================
# Full production settings with high availability
# - Large address space for growth
# - NAT Gateway enabled for secure outbound
# - All availability zones
# - DDoS Protection ready (enable if needed)
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "prod"
location    = "${{ values.location }}"
description = "${{ values.description }}"
owner       = "${{ values.owner }}"

# Network Configuration - Large /16 for production
address_space = "10.2.0.0/16"

# Subnet CIDRs - Large production-scale sizing
public_subnet_cidr   = "10.2.0.0/20"   # 4094 hosts
private_subnet_cidr  = "10.2.16.0/20"  # 4094 hosts
database_subnet_cidr = "10.2.32.0/22"  # 1022 hosts
aks_subnet_cidr      = "10.2.64.0/18"  # 16382 hosts

# NAT Gateway - Enabled for production
enable_nat_gateway = true
nat_idle_timeout   = 15

# Availability Zones - All zones for HA
availability_zones = ["1", "2", "3"]

# DDoS Protection - Enable for production if required
# Note: DDoS Protection Plan has significant cost (~$2,944/month)
enable_ddos_protection = false

# Tags
tags = {
  CostCenter    = "production"
  Criticality   = "high"
  Compliance    = "required"
  BackupEnabled = "true"
}
