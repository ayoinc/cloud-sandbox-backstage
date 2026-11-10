# =============================================================================
# Development Environment Configuration
# =============================================================================
# This file contains environment-specific values for the development environment.
# These values are populated by Backstage scaffolder during project creation.
# =============================================================================

# Core Configuration
name        = "${{ values.name }}"
environment = "dev"

# Network Configuration
vpc_cidr                 = "${{ values.vpc_cidr }}"
availability_zones_count = ${{ values.azs }}

# Feature Flags (cost-optimized for dev)
# NAT gateways and flow logs are left out of dev to save cost
enable_nat_gateway = false
enable_flow_logs   = false

# Tags
tags = {
  Environment = "dev"
  Project     = "${{ values.name }}"
  Owner       = "${{ values.owner }}"
  CostCenter  = "development"
}
