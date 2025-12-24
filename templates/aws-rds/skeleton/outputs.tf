# =============================================================================
# AWS RDS - Root Outputs
# =============================================================================
# Output values from the RDS module exposed at the root level.
# =============================================================================

# -----------------------------------------------------------------------------
# Instance Outputs
# -----------------------------------------------------------------------------
output "instance_id" {
  description = "The RDS instance ID"
  value       = module.rds.instance_id
}

output "instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.rds.instance_arn
}

output "instance_identifier" {
  description = "The RDS instance identifier"
  value       = module.rds.instance_identifier
}

# -----------------------------------------------------------------------------
# Connection Outputs
# -----------------------------------------------------------------------------
output "endpoint" {
  description = "The connection endpoint in address:port format"
  value       = module.rds.endpoint
}

output "address" {
  description = "The hostname of the RDS instance"
  value       = module.rds.address
}

output "port" {
  description = "The database port"
  value       = module.rds.port
}

output "database_name" {
  description = "The name of the default database"
  value       = module.rds.database_name
}

# -----------------------------------------------------------------------------
# Secrets Manager Outputs
# -----------------------------------------------------------------------------
output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = module.rds.secret_arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret containing database credentials"
  value       = module.rds.secret_name
}

# -----------------------------------------------------------------------------
# Security Group Outputs
# -----------------------------------------------------------------------------
output "security_group_id" {
  description = "ID of the RDS security group"
  value       = module.rds.security_group_id
}

# -----------------------------------------------------------------------------
# Subnet Group Outputs
# -----------------------------------------------------------------------------
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = module.rds.db_subnet_group_name
}

# -----------------------------------------------------------------------------
# Parameter Group Outputs
# -----------------------------------------------------------------------------
output "parameter_group_name" {
  description = "Name of the DB parameter group"
  value       = module.rds.parameter_group_name
}

# -----------------------------------------------------------------------------
# Engine Information
# -----------------------------------------------------------------------------
output "engine" {
  description = "The database engine"
  value       = module.rds.engine
}

output "engine_version" {
  description = "The database engine version"
  value       = module.rds.engine_version
}

output "instance_class" {
  description = "The RDS instance class"
  value       = module.rds.instance_class
}

# -----------------------------------------------------------------------------
# High Availability
# -----------------------------------------------------------------------------
output "multi_az" {
  description = "Whether the RDS instance is multi-AZ"
  value       = module.rds.multi_az
}

output "availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = module.rds.availability_zone
}

# -----------------------------------------------------------------------------
# Connection String Helper
# -----------------------------------------------------------------------------
output "connection_info" {
  description = "Database connection information (retrieve password from Secrets Manager)"
  value = {
    host          = module.rds.address
    port          = module.rds.port
    database      = module.rds.database_name
    secret_arn    = module.rds.secret_arn
    engine        = module.rds.engine
    instance_type = module.rds.instance_class
  }
}
