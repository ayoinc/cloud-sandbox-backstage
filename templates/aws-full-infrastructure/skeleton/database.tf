# -----------------------------------------------------------------------------
# Network placement shared by RDS and ElastiCache
# -----------------------------------------------------------------------------
resource "aws_security_group" "database" {
  count = var.enable_database ? 1 : 0

  name        = "${local.name}-database"
  description = "Databases of the ${local.name} stack"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${local.name}-database"
  }
}

resource "aws_vpc_security_group_ingress_rule" "database_postgres" {
  count = var.enable_database ? 1 : 0

  security_group_id = aws_security_group.database[0].id
  description       = "PostgreSQL from inside the VPC"
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
  cidr_ipv4         = var.vpc_cidr
}

# -----------------------------------------------------------------------------
# RDS for PostgreSQL
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  count = var.enable_database ? 1 : 0

  name       = local.name
  subnet_ids = local.private_subnet_ids
}

resource "aws_db_parameter_group" "main" {
  count = var.enable_database ? 1 : 0

  name_prefix = "${local.name}-"
  family      = "postgres${var.rds_engine_version}"

  # Clients must connect over TLS.
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "rds_monitoring" {
  count = var.enable_database ? 1 : 0

  name = "${local.name}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.enable_database ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "main" {
  # checkov:skip=CKV_AWS_157: Multi-AZ is on for the prod and dr environments; the others run a single instance to save cost (rds_multi_az)
  # checkov:skip=CKV_AWS_293: Deletion protection is on for the prod and dr environments; the others can be torn down (deletion_protection)
  count = var.enable_database ? 1 : 0

  identifier     = local.name
  engine         = "postgres"
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.main.arn

  db_name  = "app"
  username = "dbadmin"

  # RDS creates the master password, keeps it in Secrets Manager and rotates it.
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.main.arn

  db_subnet_group_name                = aws_db_subnet_group.main[0].name
  vpc_security_group_ids              = [aws_security_group.database[0].id]
  parameter_group_name                = aws_db_parameter_group.main[0].name
  publicly_accessible                 = false
  multi_az                            = var.rds_multi_az
  iam_database_authentication_enabled = true

  backup_retention_period   = var.rds_backup_retention
  copy_tags_to_snapshot     = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = !var.deletion_protection
  final_snapshot_identifier = var.deletion_protection ? "${local.name}-final" : null

  auto_minor_version_upgrade            = true
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring[0].arn
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.main.arn
  performance_insights_retention_period = 7

  depends_on = [aws_iam_role_policy_attachment.rds_monitoring]
}

# -----------------------------------------------------------------------------
# DynamoDB table (optional)
# -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "main" {
  count = var.enable_database && var.enable_dynamodb ? 1 : 0

  name                        = local.name
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "pk"
  range_key                   = "sk"
  deletion_protection_enabled = var.deletion_protection

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.main.arn
  }
}

# -----------------------------------------------------------------------------
# ElastiCache for Redis (optional)
# -----------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "database_redis" {
  count = var.enable_database && var.enable_elasticache ? 1 : 0

  security_group_id = aws_security_group.database[0].id
  description       = "Redis from inside the VPC"
  ip_protocol       = "tcp"
  from_port         = 6379
  to_port           = 6379
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_elasticache_subnet_group" "main" {
  count = var.enable_database && var.enable_elasticache ? 1 : 0

  name       = local.name
  subnet_ids = local.private_subnet_ids
}

resource "random_password" "redis" {
  count = var.enable_database && var.enable_elasticache ? 1 : 0

  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "redis" {
  # checkov:skip=CKV2_AWS_57: Rotating the Redis AUTH token needs a rotation function, which this stack does not create
  count = var.enable_database && var.enable_elasticache ? 1 : 0

  name        = "${local.name}-redis-auth"
  description = "AUTH token of the ${local.name} Redis replication group"
  kms_key_id  = aws_kms_key.main.arn
}

resource "aws_secretsmanager_secret_version" "redis" {
  count = var.enable_database && var.enable_elasticache ? 1 : 0

  secret_id     = aws_secretsmanager_secret.redis[0].id
  secret_string = random_password.redis[0].result
}

resource "aws_elasticache_replication_group" "main" {
  count = var.enable_database && var.enable_elasticache ? 1 : 0

  replication_group_id = local.name
  description          = "Redis of the ${local.name} stack"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.elasticache_node_type
  port                 = 6379

  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true

  subnet_group_name  = aws_elasticache_subnet_group.main[0].name
  security_group_ids = [aws_security_group.database[0].id]

  at_rest_encryption_enabled = true
  kms_key_id                 = aws_kms_key.main.arn
  transit_encryption_enabled = true
  auth_token                 = random_password.redis[0].result

  snapshot_retention_limit   = 7
  auto_minor_version_upgrade = true
}
