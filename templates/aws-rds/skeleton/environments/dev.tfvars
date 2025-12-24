# =============================================================================
# AWS RDS - Development Environment Configuration
# =============================================================================
# Cost-optimized settings for development workloads.
# - Smaller instance types
# - No Multi-AZ (single AZ for cost savings)
# - Shorter backup retention
# - No deletion protection
# - Monitoring disabled to reduce costs
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "dev"

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
# Instance Configuration (cost-optimized)
# -----------------------------------------------------------------------------
instance_class = "db.t3.micro"

# -----------------------------------------------------------------------------
# Storage Configuration
# -----------------------------------------------------------------------------
allocated_storage     = 20
max_allocated_storage = 50
storage_type          = "gp3"
storage_encrypted     = true

# -----------------------------------------------------------------------------
# Database Settings
# -----------------------------------------------------------------------------
database_name   = "${{ values.databaseName }}"
master_username = "dbadmin"

# -----------------------------------------------------------------------------
# High Availability (disabled for dev)
# -----------------------------------------------------------------------------
multi_az = false

# -----------------------------------------------------------------------------
# Backup Configuration (minimal for dev)
# -----------------------------------------------------------------------------
backup_retention_period = 7
backup_window           = "03:00-04:00"
maintenance_window      = "Mon:04:00-Mon:05:00"
skip_final_snapshot     = true
deletion_protection     = false

# -----------------------------------------------------------------------------
# Monitoring (disabled for cost savings)
# -----------------------------------------------------------------------------
performance_insights_enabled          = false
performance_insights_retention_period = 7
monitoring_interval                   = 0

# -----------------------------------------------------------------------------
# Maintenance
# -----------------------------------------------------------------------------
auto_minor_version_upgrade = true
apply_immediately          = true

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
tags = {
  Project     = "${{ values.name }}"
  Environment = "dev"
  Owner       = "${{ values.owner }}"
  CostCenter  = "development"
  ManagedBy   = "terraform"
}
