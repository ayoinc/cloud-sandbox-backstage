# =============================================================================
# AWS RDS - Production Environment Configuration
# =============================================================================
# Full production settings with high availability and security.
# - Production instance types
# - Multi-AZ enabled for high availability
# - Extended backup retention (30 days)
# - Deletion protection enabled
# - Full monitoring and Performance Insights
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "prod"
region      = "${{ values.region }}"

# -----------------------------------------------------------------------------
# Network Configuration (from existing VPC)
# -----------------------------------------------------------------------------
vpc_id             = "${{ values.vpcId }}"
private_subnet_ids = ["${{ values.privateSubnetIds | join('", "') }}"]
vpc_cidr_block     = "${{ values.vpcCidrBlock }}"

# -----------------------------------------------------------------------------
# Database Engine
# -----------------------------------------------------------------------------
engine         = "${{ values.engine }}"
engine_version = "${{ values.engineVersion }}"
engine_family  = "${{ values.engineFamily }}"

# -----------------------------------------------------------------------------
# Instance Configuration (production)
# -----------------------------------------------------------------------------
instance_class = "${{ values.instanceClass }}"

# -----------------------------------------------------------------------------
# Storage Configuration
# -----------------------------------------------------------------------------
allocated_storage     = ${{ values.allocatedStorage }}
max_allocated_storage = ${{ values.allocatedStorage * 5 }}
storage_type          = "gp3"
storage_encrypted     = true

# -----------------------------------------------------------------------------
# Database Settings
# -----------------------------------------------------------------------------
database_name   = "${{ values.databaseName }}"
master_username = "dbadmin"

# -----------------------------------------------------------------------------
# High Availability (ENABLED for production)
# -----------------------------------------------------------------------------
multi_az = ${{ values.multiAz }}

# -----------------------------------------------------------------------------
# Backup Configuration (extended for production)
# -----------------------------------------------------------------------------
backup_retention_period = 30
backup_window           = "03:00-04:00"
maintenance_window      = "Mon:04:00-Mon:05:00"
skip_final_snapshot     = false
deletion_protection     = true

# -----------------------------------------------------------------------------
# Monitoring (full monitoring enabled)
# -----------------------------------------------------------------------------
performance_insights_enabled          = true
performance_insights_retention_period = 31
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
  Environment = "prod"
  Owner       = "${{ values.owner }}"
  CostCenter  = "production"
  ManagedBy   = "terraform"
  Compliance  = "required"
}
