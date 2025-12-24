# =============================================================================
# AWS RDS - Staging Environment Configuration
# =============================================================================
# Production-like settings for testing and validation.
# - Moderate instance types
# - Optional Multi-AZ (typically disabled for cost)
# - Moderate backup retention
# - Monitoring enabled
# - No deletion protection
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "staging"

# -----------------------------------------------------------------------------
# Network Configuration (from existing VPC)
# -----------------------------------------------------------------------------
vpc_id             = "${{ values.vpcId }}"
private_subnet_ids = ${{ values.privateSubnetIds | dump }}
vpc_cidr_block     = "${{ values.vpcCidrBlock }}"

# -----------------------------------------------------------------------------
# Database Engine
# -----------------------------------------------------------------------------
engine         = "${{ values.engine }}"
engine_version = "${{ values.engineVersion }}"
engine_family  = "${{ values.engineFamily }}"

# -----------------------------------------------------------------------------
# Instance Configuration (moderate)
# -----------------------------------------------------------------------------
instance_class = "db.t3.small"

# -----------------------------------------------------------------------------
# Storage Configuration
# -----------------------------------------------------------------------------
allocated_storage     = 50
max_allocated_storage = 100
storage_type          = "gp3"
storage_encrypted     = true

# -----------------------------------------------------------------------------
# Database Settings
# -----------------------------------------------------------------------------
database_name   = "${{ values.databaseName }}"
master_username = "dbadmin"

# -----------------------------------------------------------------------------
# High Availability (optional for staging)
# -----------------------------------------------------------------------------
multi_az = false

# -----------------------------------------------------------------------------
# Backup Configuration (moderate)
# -----------------------------------------------------------------------------
backup_retention_period = 14
backup_window           = "03:00-04:00"
maintenance_window      = "Mon:04:00-Mon:05:00"
skip_final_snapshot     = true
deletion_protection     = false

# -----------------------------------------------------------------------------
# Monitoring (enabled for testing)
# -----------------------------------------------------------------------------
performance_insights_enabled          = true
performance_insights_retention_period = 7
monitoring_interval                   = 60

# -----------------------------------------------------------------------------
# Maintenance
# -----------------------------------------------------------------------------
auto_minor_version_upgrade = true
apply_immediately          = false

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
tags = {
  Project     = "${{ values.name }}"
  Environment = "staging"
  Owner       = "${{ values.owner }}"
  CostCenter  = "staging"
  ManagedBy   = "terraform"
}
