output "instance_name" {
  description = "Name of the Cloud SQL instance."
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "Connection name of the instance (<project>:<region>:<name>) for the Cloud SQL connectors."
  value       = google_sql_database_instance.main.connection_name
}

output "instance_self_link" {
  description = "Self link of the Cloud SQL instance."
  value       = google_sql_database_instance.main.self_link
}

output "private_ip_address" {
  description = "Private IP address of the Cloud SQL instance."
  value       = google_sql_database_instance.main.private_ip_address
}

output "database_name" {
  description = "Name of the application database."
  value       = google_sql_database.main.name
}

output "user_name" {
  description = "Name of the application database user."
  value       = google_sql_user.main.name
}

output "credentials_secret_id" {
  description = "ID of the Secret Manager secret holding the database connection details as JSON."
  value       = google_secret_manager_secret.database.id
}

output "credentials_secret_name" {
  description = "Short name of the Secret Manager secret holding the database connection details."
  value       = google_secret_manager_secret.database.secret_id
}

output "private_ip_range_name" {
  description = "Name of the allocated range the instances take their addresses from."
  value       = local.private_ip_range
}

output "redis_host" {
  description = "Host of the Redis instance, or null when disabled."
  value       = var.enable_redis ? google_redis_instance.main[0].host : null
}

output "redis_port" {
  description = "Port of the Redis instance, or null when disabled."
  value       = var.enable_redis ? google_redis_instance.main[0].port : null
}

output "redis_credentials_secret_id" {
  description = "ID of the Secret Manager secret holding the Redis connection details as JSON, or null when disabled."
  value       = var.enable_redis ? google_secret_manager_secret.redis[0].id : null
}
