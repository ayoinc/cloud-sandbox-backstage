output "instance_id" {
  description = "The ID of the Spanner instance"
  value       = google_spanner_instance.this.id
}

output "instance_name" {
  description = "The name of the Spanner instance"
  value       = google_spanner_instance.this.name
}

output "instance_state" {
  description = "The state of the Spanner instance"
  value       = google_spanner_instance.this.state
}

output "database_ids" {
  description = "Map of database names to their IDs"
  value       = { for k, v in google_spanner_database.this : k => v.id }
}

output "database_states" {
  description = "Map of database names to their states"
  value       = { for k, v in google_spanner_database.this : k => v.state }
}
