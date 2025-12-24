# =============================================================================
# Staging Environment Configuration
# =============================================================================
# This file contains environment-specific values for the staging environment.
# These values are populated by Backstage scaffolder during project creation.
# =============================================================================

# Core Configuration
name        = "${{ values.name }}"
environment = "staging"

# Network Configuration
vpc_cidr                 = "${{ values.vpc_cidr }}"
availability_zones_count = ${{ values.azs }}

# Feature Flags (production-like but cost-conscious)
enable_nat_gateway = true
enable_flow_logs   = true

# Flow Logs Configuration
flow_logs_retention_days = 7

# Tags
tags = {
  Environment = "staging"
  Project     = "${{ values.name }}"
  Owner       = "${{ values.owner }}"
  CostCenter  = "staging"
}
