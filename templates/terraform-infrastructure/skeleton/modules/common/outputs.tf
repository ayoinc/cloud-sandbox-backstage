# Common Module Outputs

output "database_password" {
  description = "Generated database password"
  value       = var.enable_database ? random_password.database_password[0].result : null
  sensitive   = true
}

output "resource_suffix" {
  description = "Random suffix for unique resource naming"
  value       = random_id.suffix.hex
}

output "resource_suffix_dec" {
  description = "Random suffix in decimal format"
  value       = random_id.suffix.dec
}

output "resource_uuid" {
  description = "Generated UUID for resource identification"
  value       = var.generate_uuid ? random_uuid.resource_id[0].result : null
}
