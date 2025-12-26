# -----------------------------------------------------------------------------
# AWS Database Module - Outputs
# -----------------------------------------------------------------------------

# RDS Outputs
output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_address" {
  description = "RDS address (hostname)"
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "db_port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Database username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_credentials_secret_arn" {
  description = "Database credentials secret ARN"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.main.name
}

# ElastiCache Outputs
output "redis_endpoint" {
  description = "Redis primary endpoint"
  value       = var.enable_elasticache ? aws_elasticache_replication_group.main[0].primary_endpoint_address : null
  sensitive   = true
}

output "redis_reader_endpoint" {
  description = "Redis reader endpoint"
  value       = var.enable_elasticache ? aws_elasticache_replication_group.main[0].reader_endpoint_address : null
  sensitive   = true
}

output "redis_port" {
  description = "Redis port"
  value       = var.enable_elasticache ? 6379 : null
}

output "redis_credentials_secret_arn" {
  description = "Redis credentials secret ARN"
  value       = var.enable_elasticache ? aws_secretsmanager_secret.redis_credentials[0].arn : null
}

output "redis_security_group_id" {
  description = "Redis security group ID"
  value       = var.enable_elasticache ? aws_security_group.elasticache[0].id : null
}
