# =============================================================================
# AWS RDS Module
# =============================================================================
# Reusable module for creating an RDS instance with security group,
# subnet group, parameter group, and Secrets Manager integration.
# =============================================================================

locals {
  identifier = "${var.name}-${var.environment}"
  db_port    = var.port != null ? var.port : (var.engine == "postgres" ? 5432 : 3306)

  # postgres16, postgres17, ... or mysql8.0, mysql8.4: PostgreSQL families use
  # the major version, MySQL families the major and minor version.
  version_parts = split(".", var.engine_version)
  derived_family = (
    var.engine == "postgres"
    ? "postgres${local.version_parts[0]}"
    : "mysql${join(".", slice(concat(local.version_parts, ["0"]), 0, 2))}"
  )
  engine_family = var.engine_family != null ? var.engine_family : local.derived_family

  # Performance Insights is not available for MySQL on micro and small classes.
  performance_insights_supported = !(var.engine == "mysql" && can(regex("\\.(micro|small)$", var.instance_class)))
  performance_insights_enabled   = var.performance_insights_enabled && local.performance_insights_supported

  # CloudWatch log exports based on engine
  default_log_exports = var.engine == "postgres" ? ["postgresql", "upgrade"] : ["error", "slowquery"]
  log_exports         = length(var.enabled_cloudwatch_logs_exports) > 0 ? var.enabled_cloudwatch_logs_exports : local.default_log_exports
}

# -----------------------------------------------------------------------------
# KMS key for storage, Performance Insights and the credentials secret
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

resource "aws_kms_key" "this" {
  description             = "Encryption key for the ${local.identifier} database"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AccountAdministration"
      Effect    = "Allow"
      Principal = { AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = "kms:*"
      Resource  = "*"
    }]
  })

  tags = merge(var.tags, {
    Name = "${local.identifier}-rds"
  })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${local.identifier}-rds"
  target_key_id = aws_kms_key.this.key_id
}

# -----------------------------------------------------------------------------
# Random Password for Master User
# -----------------------------------------------------------------------------
resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# -----------------------------------------------------------------------------
# Secrets Manager - Store Database Credentials
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "db_credentials" {
  # checkov:skip=CKV2_AWS_57: Rotation needs a rotation function inside the VPC, which this template does not create
  name        = "${local.identifier}-db-credentials"
  description = "Database credentials for ${var.name}"
  kms_key_id  = aws_kms_key.this.arn

  tags = merge(var.tags, {
    Name = "${local.identifier}-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    database = var.database_name
    engine   = var.engine
  })
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "this" {
  name        = "${local.identifier}-rds-sg"
  description = "Security group for RDS instance ${var.name}"
  vpc_id      = var.vpc_id

  ingress {
    description = "Database port from VPC"
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(var.tags, {
    Name = "${local.identifier}-rds-sg"
  })
}

# -----------------------------------------------------------------------------
# DB Subnet Group
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "this" {
  name       = "${local.identifier}-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${local.identifier}-subnet-group"
  })
}

# -----------------------------------------------------------------------------
# DB Parameter Group
# -----------------------------------------------------------------------------
resource "aws_db_parameter_group" "this" {
  name   = "${local.identifier}-params"
  family = local.engine_family

  # Clients must connect over TLS.
  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [1] : []
    content {
      name  = "rds.force_ssl"
      value = "1"
    }
  }

  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [] : [1]
    content {
      name  = "require_secure_transport"
      value = "1"
    }
  }

  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [1] : []
    content {
      name  = "log_statement"
      value = "all"
    }
  }

  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [1] : []
    content {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  }

  tags = merge(var.tags, {
    Name = "${local.identifier}-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# IAM Role for Enhanced Monitoring
# -----------------------------------------------------------------------------
resource "aws_iam_role" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  name  = "${local.identifier}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${local.identifier}-rds-monitoring"
  })
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# -----------------------------------------------------------------------------
# RDS Instance
# -----------------------------------------------------------------------------
resource "aws_db_instance" "this" {
  # checkov:skip=CKV2_AWS_69: TLS is enforced by rds.force_ssl / require_secure_transport in the parameter group; Checkov does not follow the per-engine dynamic blocks
  # checkov:skip=CKV_AWS_157: Multi-AZ is a choice made when the repository is created (multi_az in environments/*.tfvars)
  identifier = local.identifier

  # Engine Configuration
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage Configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id != null ? var.kms_key_id : aws_kms_key.this.arn

  # Database Configuration
  db_name  = var.database_name
  username = var.master_username
  password = random_password.master.result
  port     = local.db_port

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Backup Configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  copy_tags_to_snapshot   = true

  # Monitoring Configuration
  performance_insights_enabled          = local.performance_insights_enabled
  performance_insights_retention_period = local.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = local.performance_insights_enabled ? aws_kms_key.this.arn : null
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? aws_iam_role.monitoring[0].arn : null
  enabled_cloudwatch_logs_exports       = local.log_exports

  # Maintenance Configuration
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  # Deletion Configuration
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.identifier}-final-snapshot"

  # Parameter Group
  parameter_group_name = aws_db_parameter_group.this.name

  # Ensure dependencies are created first
  depends_on = [
    aws_iam_role_policy_attachment.monitoring,
  ]

  tags = merge(var.tags, {
    Name = local.identifier
  })
}
