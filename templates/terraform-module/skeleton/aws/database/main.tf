# -----------------------------------------------------------------------------
# AWS Database Module - Main Resources
# -----------------------------------------------------------------------------

data "aws_partition" "current" {}

locals {
  # Lowercase, hyphen-separated and short enough for every AWS name limit.
  project     = trimsuffix(substr(replace(lower(var.project_name), "/[^a-z0-9]+/", "-"), 0, 23), "-")
  name_prefix = "${local.project}-${var.environment}"

  # Secrets of the project live under this path.
  path_prefix = "${local.project}/${var.environment}"

  db_port = var.engine == "postgres" ? 5432 : 3306

  # Major versions used when engine_version is not set.
  default_engine_versions = {
    postgres = "17"
    mysql    = "8.4"
    mariadb  = "11.4"
  }
  engine_version = coalesce(var.engine_version, local.default_engine_versions[var.engine])

  # Parameter group families are named after the major version: one number
  # for PostgreSQL, two for MySQL and MariaDB.
  version_parts          = split(".", local.engine_version)
  parameter_group_family = var.engine == "postgres" ? "postgres${local.version_parts[0]}" : "${var.engine}${local.version_parts[0]}.${local.version_parts[1]}"

  # Connections must use TLS on every engine.
  tls_parameters = var.engine == "postgres" ? [
    { name = "rds.force_ssl", value = "1", apply_method = "immediate" }
    ] : [
    { name = "require_secure_transport", value = "1", apply_method = "immediate" }
  ]
  db_parameters = concat(local.tls_parameters, var.db_parameters)

  default_log_exports = var.engine == "postgres" ? ["postgresql", "upgrade"] : ["error", "slowquery"]
  log_exports         = var.cloudwatch_logs_exports != null ? var.cloudwatch_logs_exports : local.default_log_exports
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-db-subnet-group"
  })
}

# Security Group for RDS. It has no egress rules: the database never opens
# connections itself.
resource "aws_security_group" "rds" {
  name_prefix = "${local.name_prefix}-rds-"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_security_group" {
  count = length(var.allowed_security_groups)

  security_group_id            = aws_security_group.rds.id
  description                  = "Database access from an allowed security group"
  ip_protocol                  = "tcp"
  from_port                    = local.db_port
  to_port                      = local.db_port
  referenced_security_group_id = var.allowed_security_groups[count.index]

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "rds_cidr" {
  count = length(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.rds.id
  description       = "Database access from an allowed network"
  ip_protocol       = "tcp"
  from_port         = local.db_port
  to_port           = local.db_port
  cidr_ipv4         = var.allowed_cidr_blocks[count.index]

  tags = var.tags
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  name_prefix = "${local.name_prefix}-db-"
  family      = local.parameter_group_family
  description = "Parameters for ${local.name_prefix}"

  dynamic "parameter" {
    for_each = local.db_parameters
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

# Admin password, kept in Secrets Manager together with the connection details
resource "random_password" "db_password" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${local.path_prefix}/db-credentials"
  description             = "Admin credentials and endpoint of the ${local.name_prefix} database"
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
    port     = local.db_port
    dbname   = var.db_name
  })
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-db"

  # Engine configuration
  engine         = var.engine
  engine_version = local.engine_version
  instance_class = var.instance_class

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  iops                  = var.iops
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
  enabled_cloudwatch_logs_exports       = local.log_exports
  monitoring_interval                   = var.enhanced_monitoring_interval
  monitoring_role_arn                   = var.enhanced_monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  # Deletion protection; production keeps a final snapshot
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${local.name_prefix}-final-snapshot" : null

  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-db"
  })

  depends_on = [aws_iam_role_policy_attachment.rds_monitoring]
}

# Enhanced Monitoring Role
resource "aws_iam_role" "rds_monitoring" {
  count = var.enhanced_monitoring_interval > 0 ? 1 : 0

  name = "${local.name_prefix}-rds-monitoring-role"

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
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# -----------------------------------------------------------------------------
# ElastiCache Redis Cluster
# -----------------------------------------------------------------------------

resource "aws_elasticache_subnet_group" "main" {
  count = var.enable_elasticache ? 1 : 0

  name       = "${local.name_prefix}-cache-subnet-group"
  subnet_ids = var.subnet_ids

  tags = var.tags
}

# No egress rules: the cache never opens connections itself.
resource "aws_security_group" "elasticache" {
  count = var.enable_elasticache ? 1 : 0

  name_prefix = "${local.name_prefix}-cache-"
  description = "Security group for ElastiCache"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-cache-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "elasticache_security_group" {
  count = var.enable_elasticache ? length(var.allowed_security_groups) : 0

  security_group_id            = aws_security_group.elasticache[0].id
  description                  = "Redis access from an allowed security group"
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = var.allowed_security_groups[count.index]

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "elasticache_cidr" {
  count = var.enable_elasticache ? length(var.allowed_cidr_blocks) : 0

  security_group_id = aws_security_group.elasticache[0].id
  description       = "Redis access from an allowed network"
  ip_protocol       = "tcp"
  from_port         = 6379
  to_port           = 6379
  cidr_ipv4         = var.allowed_cidr_blocks[count.index]

  tags = var.tags
}

resource "random_password" "redis_auth" {
  count = var.enable_elasticache ? 1 : 0

  length  = 32
  special = false
}

resource "aws_elasticache_replication_group" "main" {
  count = var.enable_elasticache ? 1 : 0

  replication_group_id = "${local.name_prefix}-cache"
  description          = "Redis cluster for ${local.name_prefix}"

  engine               = "redis"
  engine_version       = var.cache_engine_version
  parameter_group_name = "default.redis7"
  node_type            = var.cache_node_type
  num_cache_clusters   = var.cache_num_nodes
  port                 = 6379

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

  auto_minor_version_upgrade = true

  tags = var.tags
}

resource "aws_secretsmanager_secret" "redis_credentials" {
  count = var.enable_elasticache ? 1 : 0

  name                    = "${local.path_prefix}/redis-credentials"
  description             = "Auth token and endpoint of the ${local.name_prefix} Redis cache"
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
    tls        = true
  })
}
