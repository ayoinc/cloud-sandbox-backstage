# =============================================================================
# AWS RDS Module - Outputs
# =============================================================================
# Output values from the RDS module for use by other modules or resources.
# =============================================================================

# -----------------------------------------------------------------------------
# Instance Outputs
# -----------------------------------------------------------------------------
output "instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.this.id
}

output "instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "instance_identifier" {
  description = "The RDS instance identifier"
  value       = aws_db_instance.this.identifier
}

output "instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = aws_db_instance.this.resource_id
}

# -----------------------------------------------------------------------------
# Connection Outputs
# -----------------------------------------------------------------------------
output "endpoint" {
  description = "The connection endpoint in address:port format"
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "The database port"
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "The name of the default database"
  value       = aws_db_instance.this.db_name
}

output "master_username" {
  description = "The master username for the database"
  value       = aws_db_instance.this.username
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Secrets Manager Outputs
# -----------------------------------------------------------------------------
output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_credentials.name
}

# -----------------------------------------------------------------------------
# Security Group Outputs
# -----------------------------------------------------------------------------
output "security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "ARN of the RDS security group"
  value       = aws_security_group.this.arn
}

# -----------------------------------------------------------------------------
# Subnet Group Outputs
# -----------------------------------------------------------------------------
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.this.name
}

output "db_subnet_group_arn" {
  description = "ARN of the DB subnet group"
  value       = aws_db_subnet_group.this.arn
}

# -----------------------------------------------------------------------------
# Parameter Group Outputs
# -----------------------------------------------------------------------------
output "parameter_group_name" {
  description = "Name of the DB parameter group"
  value       = aws_db_parameter_group.this.name
}

output "parameter_group_arn" {
  description = "ARN of the DB parameter group"
  value       = aws_db_parameter_group.this.arn
}

# -----------------------------------------------------------------------------
# Monitoring Outputs
# -----------------------------------------------------------------------------
output "monitoring_role_arn" {
  description = "ARN of the IAM role used for enhanced monitoring"
  value       = var.monitoring_interval > 0 ? aws_iam_role.monitoring[0].arn : null
}

# -----------------------------------------------------------------------------
# Engine Information
# -----------------------------------------------------------------------------
output "engine" {
  description = "The database engine"
  value       = aws_db_instance.this.engine
}

output "engine_version" {
  description = "The database engine version"
  value       = aws_db_instance.this.engine_version
}

output "instance_class" {
  description = "The RDS instance class"
  value       = aws_db_instance.this.instance_class
}

# -----------------------------------------------------------------------------
# Storage Information
# -----------------------------------------------------------------------------
output "allocated_storage" {
  description = "The amount of allocated storage in GB"
  value       = aws_db_instance.this.allocated_storage
}

output "storage_encrypted" {
  description = "Whether the DB instance is encrypted"
  value       = aws_db_instance.this.storage_encrypted
}

# -----------------------------------------------------------------------------
# High Availability
# -----------------------------------------------------------------------------
output "multi_az" {
  description = "Whether the RDS instance is multi-AZ"
  value       = aws_db_instance.this.multi_az
}

output "availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = aws_db_instance.this.availability_zone
}
