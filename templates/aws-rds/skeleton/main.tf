# =============================================================================
# AWS RDS Infrastructure
# =============================================================================
# Root module that calls the RDS child module.
# Environment-specific values are provided via -var-file.
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# -----------------------------------------------------------------------------
# RDS Module
# -----------------------------------------------------------------------------
module "rds" {
  source = "./modules/rds"

  # Project Configuration
  name        = var.name
  environment = var.environment

  # Network Configuration
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  vpc_cidr_block     = var.vpc_cidr_block

  # Database Engine
  engine         = var.engine
  engine_version = var.engine_version
  engine_family  = var.engine_family

  # Instance Configuration
  instance_class = var.instance_class

  # Storage Configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  # Database Settings
  database_name   = var.database_name
  master_username = var.master_username
  port            = var.port

  # High Availability
  multi_az = var.multi_az

  # Backup Configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection

  # Monitoring
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  monitoring_interval                   = var.monitoring_interval
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports

  # Network
  publicly_accessible = var.publicly_accessible

  # Maintenance
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  # Tags
  tags = var.tags
}
