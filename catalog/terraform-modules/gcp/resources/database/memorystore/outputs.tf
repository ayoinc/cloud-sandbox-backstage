output "instance_id" {
  description = "The unique identifier of the Redis instance"
  value       = google_redis_instance.this.id
}

output "instance_name" {
  description = "The name of the Redis instance"
  value       = google_redis_instance.this.name
}

output "host" {
  description = "The IP address of the Redis instance"
  value       = google_redis_instance.this.host
}

output "port" {
  description = "The port number of the Redis instance"
  value       = google_redis_instance.this.port
}

output "current_location_id" {
  description = "The current zone where the Redis instance is placed"
  value       = google_redis_instance.this.current_location_id
}

output "auth_string" {
  description = "The AUTH string for the Redis instance (only available when auth_enabled is true)"
  value       = google_redis_instance.this.auth_string
  sensitive   = true
}

output "persistence_iam_identity" {
  description = "The IAM identity used for persistence operations"
  value       = google_redis_instance.this.persistence_iam_identity
}
