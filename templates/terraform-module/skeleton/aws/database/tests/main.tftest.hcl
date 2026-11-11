mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "eu-west-2"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }

  mock_data "aws_vpc" {
    defaults = {
      cidr_block = "10.0.0.0/16"
    }
  }
}

variables {
  project_name = "My_Project"
  environment  = "dev"
  vpc_id       = "vpc-0123456789abcdef0"
  subnet_ids   = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
}

run "defaults" {
  command = plan

  assert {
    condition     = aws_db_instance.main.identifier == "my-project-dev-db"
    error_message = "The instance identifier must be derived from the name prefix."
  }

  assert {
    condition     = aws_db_instance.main.engine == "postgres" && aws_db_instance.main.engine_version == "17" && aws_db_instance.main.port == 5432
    error_message = "PostgreSQL 17 on port 5432 is the default."
  }

  assert {
    condition     = aws_db_parameter_group.main.family == "postgres17"
    error_message = "The parameter group family must match the engine version."
  }

  assert {
    condition     = contains([for p in aws_db_parameter_group.main.parameter : p.name], "rds.force_ssl")
    error_message = "TLS must be enforced through the parameter group."
  }

  assert {
    condition     = aws_db_instance.main.storage_encrypted == true && aws_db_instance.main.publicly_accessible == false
    error_message = "The database must be encrypted and private."
  }

  assert {
    condition     = aws_db_instance.main.deletion_protection == true && aws_db_instance.main.skip_final_snapshot == true && aws_db_instance.main.multi_az == false
    error_message = "Defaults: deletion protection on, single AZ, no final snapshot outside production."
  }

  assert {
    condition     = aws_db_instance.main.backup_retention_period == 7 && aws_db_instance.main.performance_insights_enabled == true && aws_db_instance.main.monitoring_interval == 60
    error_message = "Backups, Performance Insights and enhanced monitoring must be on by default."
  }

  assert {
    condition     = aws_db_instance.main.enabled_cloudwatch_logs_exports == toset(["postgresql", "upgrade"])
    error_message = "PostgreSQL logs must be exported by default."
  }

  assert {
    condition     = aws_secretsmanager_secret.db_credentials.name == "my-project/dev/db-credentials"
    error_message = "The credentials secret must live under the project path."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.rds_security_group) == 0 && length(aws_vpc_security_group_ingress_rule.rds_cidr) == 0
    error_message = "No database ingress may be open by default."
  }

  assert {
    condition     = length(aws_elasticache_replication_group.main) == 0 && output.redis_endpoint == null && output.redis_port == null
    error_message = "ElastiCache is opt-in."
  }
}

run "mysql_production" {
  command = plan

  variables {
    environment                  = "prod"
    engine                       = "mysql"
    multi_az                     = true
    instance_class               = "db.t3.medium"
    kms_key_arn                  = "arn:aws:kms:eu-west-2:123456789012:key/11111111-2222-3333-4444-555555555555"
    allowed_security_groups      = ["sg-0123456789abcdef0"]
    allowed_cidr_blocks          = ["10.0.0.0/16"]
    enhanced_monitoring_interval = 0
    db_parameters = [{
      name  = "max_connections"
      value = "200"
    }]
  }

  assert {
    condition     = aws_db_instance.main.engine_version == "8.4" && aws_db_instance.main.port == 3306 && aws_db_parameter_group.main.family == "mysql8.4"
    error_message = "MySQL 8.4 on port 3306 with the matching parameter group family is expected."
  }

  assert {
    condition     = toset([for p in aws_db_parameter_group.main.parameter : p.name]) == toset(["require_secure_transport", "max_connections"])
    error_message = "TLS enforcement and the extra parameter must both be set."
  }

  assert {
    condition     = aws_db_instance.main.enabled_cloudwatch_logs_exports == toset(["error", "slowquery"])
    error_message = "MySQL error and slow query logs must be exported by default."
  }

  assert {
    condition     = aws_db_instance.main.multi_az == true && aws_db_instance.main.kms_key_id == var.kms_key_arn && aws_db_instance.main.performance_insights_kms_key_id == var.kms_key_arn
    error_message = "Multi-AZ and the supplied KMS key must be applied."
  }

  assert {
    condition     = aws_db_instance.main.skip_final_snapshot == false && aws_db_instance.main.final_snapshot_identifier == "my-project-prod-final-snapshot"
    error_message = "Production must keep a final snapshot."
  }

  assert {
    condition     = aws_secretsmanager_secret.db_credentials.recovery_window_in_days == 30 && aws_secretsmanager_secret.db_credentials.kms_key_id == var.kms_key_arn
    error_message = "Production secrets keep a recovery window and use the supplied key."
  }

  assert {
    condition     = length(aws_iam_role.rds_monitoring) == 0 && aws_db_instance.main.monitoring_interval == 0
    error_message = "An interval of 0 must disable enhanced monitoring and its role."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.rds_security_group[0].from_port == 3306 && aws_vpc_security_group_ingress_rule.rds_cidr[0].cidr_ipv4 == "10.0.0.0/16"
    error_message = "Ingress must be opened on the engine port for the given sources only."
  }
}

run "mariadb_pinned_version" {
  command = plan

  variables {
    engine                       = "mariadb"
    engine_version               = "10.11.9"
    performance_insights_enabled = false
    cloudwatch_logs_exports      = ["audit"]
  }

  assert {
    condition     = aws_db_instance.main.engine_version == "10.11.9" && aws_db_parameter_group.main.family == "mariadb10.11" && aws_db_instance.main.port == 3306
    error_message = "A pinned version must select the matching parameter group family."
  }

  assert {
    condition     = aws_db_instance.main.performance_insights_enabled == false
    error_message = "Performance Insights must be switchable."
  }

  assert {
    condition     = aws_db_instance.main.enabled_cloudwatch_logs_exports == toset(["audit"])
    error_message = "Explicit log exports must replace the defaults."
  }
}

run "elasticache" {
  command = plan

  variables {
    enable_elasticache      = true
    cache_num_nodes         = 2
    cache_node_type         = "cache.t3.small"
    allowed_security_groups = ["sg-0123456789abcdef0"]
  }

  assert {
    condition     = aws_elasticache_replication_group.main[0].replication_group_id == "my-project-dev-cache"
    error_message = "The replication group ID must be derived from the name prefix."
  }

  assert {
    condition     = aws_elasticache_replication_group.main[0].at_rest_encryption_enabled == "true" && aws_elasticache_replication_group.main[0].transit_encryption_enabled == true
    error_message = "The cache must be encrypted at rest and in transit."
  }

  assert {
    condition     = aws_elasticache_replication_group.main[0].automatic_failover_enabled == true && aws_elasticache_replication_group.main[0].multi_az_enabled == true && aws_elasticache_replication_group.main[0].num_cache_clusters == 2
    error_message = "Two nodes must enable failover across availability zones."
  }

  assert {
    condition     = aws_elasticache_replication_group.main[0].engine_version == "7.1" && aws_elasticache_replication_group.main[0].node_type == "cache.t3.small"
    error_message = "Engine version and node type must be applied."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.elasticache_security_group) == 1 && aws_vpc_security_group_ingress_rule.elasticache_security_group[0].from_port == 6379
    error_message = "Redis must only be reachable from the given security groups."
  }

  assert {
    condition     = aws_secretsmanager_secret.redis_credentials[0].name == "my-project/dev/redis-credentials" && output.redis_port == 6379
    error_message = "The Redis credentials secret must live under the project path."
  }
}

run "requires_vpc" {
  command = plan

  variables {
    vpc_id = null
  }

  expect_failures = [var.vpc_id]
}

run "requires_two_subnets" {
  command = plan

  variables {
    subnet_ids = ["subnet-0123456789abcdef0"]
  }

  expect_failures = [var.subnet_ids]
}

run "rejects_reserved_username" {
  command = plan

  variables {
    db_username = "admin"
  }

  expect_failures = [var.db_username]
}

run "mysql_version_needs_minor_series" {
  command = plan

  variables {
    engine         = "mysql"
    engine_version = "8"
  }

  expect_failures = [var.engine_version]
}
