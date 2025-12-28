# -----------------------------------------------------------------------------
# AWS Database Module - Main Resources
# -----------------------------------------------------------------------------

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  })
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = local.db_port
    to_port         = local.db_port
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
    description     = "Database access from allowed security groups"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  family = local.parameter_group_family
  name   = "${var.project_name}-${var.environment}-db-params"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Random password for database
resource "random_password" "db_password" {
  length  = 32
  special = false # RDS doesn't support all special chars
}

# Store password in Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_name}/${var.environment}/db-credentials"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0
  kms_key_id              = var.kms_key_arn

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = var.engine
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.db_name
  })
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"

  # Engine configuration
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  port                   = local.db_port

  # Parameter and option groups
  parameter_group_name = aws_db_parameter_group.main.name

  # Maintenance and backup
  maintenance_window      = var.maintenance_window
  backup_window           = var.backup_window
  backup_retention_period = var.backup_retention_period
  copy_tags_to_snapshot   = true

  # High availability
  multi_az = var.multi_az

  # Performance and monitoring
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.kms_key_arn : null
  enabled_cloudwatch_logs_exports       = var.cloudwatch_logs_exports
  monitoring_interval                   = var.enhanced_monitoring_interval
  monitoring_role_arn                   = var.enhanced_monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  # Deletion protection
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${var.project_name}-${var.environment}-final-snapshot" : null

  # Auto minor version upgrade
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db"
  })

  lifecycle {
    ignore_changes = [password]
  }
}

# Enhanced Monitoring Role
resource "aws_iam_role" "rds_monitoring" {
  count = var.enhanced_monitoring_interval > 0 ? 1 : 0

  name = "${var.project_name}-${var.environment}-rds-monitoring-role"

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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.enhanced_monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# -----------------------------------------------------------------------------
# ElastiCache Redis Cluster
# -----------------------------------------------------------------------------

resource "aws_elasticache_subnet_group" "main" {
  count = var.enable_elasticache ? 1 : 0

  name       = "${var.project_name}-${var.environment}-cache-subnet-group"
  subnet_ids = var.subnet_ids

  tags = var.tags
}

resource "aws_security_group" "elasticache" {
  count = var.enable_elasticache ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-cache-"
  description = "Security group for ElastiCache"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
    description     = "Redis access from allowed security groups"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cache-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_replication_group" "main" {
  count = var.enable_elasticache ? 1 : 0

  replication_group_id = "${var.project_name}-${var.environment}-cache"
  description          = "Redis cluster for ${var.project_name} ${var.environment}"

  node_type            = var.cache_node_type
  num_cache_clusters   = var.cache_num_nodes
  port                 = 6379
  parameter_group_name = "default.redis7"

  subnet_group_name  = aws_elasticache_subnet_group.main[0].name
  security_group_ids = [aws_security_group.elasticache[0].id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth[0].result
  kms_key_id                 = var.kms_key_arn

  automatic_failover_enabled = var.cache_num_nodes > 1
  multi_az_enabled           = var.cache_num_nodes > 1

  snapshot_retention_limit = var.cache_snapshot_retention
  snapshot_window          = "05:00-06:00"
  maintenance_window       = "sun:06:00-sun:07:00"

  tags = var.tags
}

resource "random_password" "redis_auth" {
  count = var.enable_elasticache ? 1 : 0

  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "redis_credentials" {
  count = var.enable_elasticache ? 1 : 0

  name                    = "${var.project_name}/${var.environment}/redis-credentials"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0
  kms_key_id              = var.kms_key_arn

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "redis_credentials" {
  count = var.enable_elasticache ? 1 : 0

  secret_id = aws_secretsmanager_secret.redis_credentials[0].id
  secret_string = jsonencode({
    auth_token = random_password.redis_auth[0].result
    endpoint   = aws_elasticache_replication_group.main[0].primary_endpoint_address
    port       = 6379
  })
}

# Locals
locals {
  db_port = var.engine == "postgres" ? 5432 : var.engine == "mysql" ? 3306 : 5432

  parameter_group_family = {
    "postgres" = "postgres15"
    "mysql"    = "mysql8.0"
    "mariadb"  = "mariadb10.6"
  }[var.engine]
}
