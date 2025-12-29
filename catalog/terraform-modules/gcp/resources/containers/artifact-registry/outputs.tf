output "repository_id" {
  description = "The ID of the repository"
  value       = google_artifact_registry_repository.this.repository_id
}

output "repository_name" {
  description = "The full name of the repository"
  value       = google_artifact_registry_repository.this.name
}

output "create_time" {
  description = "The time the repository was created"
  value       = google_artifact_registry_repository.this.create_time
}

output "update_time" {
  description = "The time the repository was last updated"
  value       = google_artifact_registry_repository.this.update_time
}
