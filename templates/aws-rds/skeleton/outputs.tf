output "endpoint" {
  description = "The connection endpoint"
  value       = aws_db_instance.main.endpoint
}

output "address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.main.address
}

output "port" {
  description = "The database port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "The name of the default database"
  value       = aws_db_instance.main.db_name
}

output "instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.main.id
}

output "arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "secret_arn" {
  description = "ARN of the secret containing database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.rds.id
}
