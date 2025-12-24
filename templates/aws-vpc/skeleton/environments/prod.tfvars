# =============================================================================
# Production Environment Configuration
# =============================================================================
# This file contains environment-specific values for the production environment.
# These values are populated by Backstage scaffolder during project creation.
# =============================================================================

# Core Configuration
name        = "${{ values.name }}"
environment = "prod"

# Network Configuration
vpc_cidr                 = "${{ values.vpc_cidr }}"
availability_zones_count = ${{ values.azs }}

# Feature Flags (full production features)
enable_nat_gateway = true
enable_flow_logs   = true

# Flow Logs Configuration (extended retention for compliance)
flow_logs_retention_days = 90
flow_logs_traffic_type   = "ALL"

# Tags
tags = {
  Environment = "prod"
  Project     = "${{ values.name }}"
  Owner       = "${{ values.owner }}"
  CostCenter  = "production"
  Compliance  = "required"
}
