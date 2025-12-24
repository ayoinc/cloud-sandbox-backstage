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
enable_nat_gateway = false  # Disable NAT for cost savings in dev
enable_flow_logs   = false  # Disable flow logs in dev

# Tags
tags = {
  Environment = "dev"
  Project     = "${{ values.name }}"
  Owner       = "${{ values.owner }}"
  CostCenter  = "development"
}
