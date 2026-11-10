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
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

# Network Configuration
address_space = "${{ values.addressSpace if (values.envName == 'prod' and values.addressSpace) else '10.2.0.0/16' }}"

# Subnets are carved out of the address space automatically: public, private
# and database each take 1/16 of it, AKS takes 1/4. Set any of these to
# override the layout:
# public_subnet_cidr   = "..."
# private_subnet_cidr  = "..."
# database_subnet_cidr = "..."
# aks_subnet_cidr      = "..."

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
