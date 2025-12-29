output "project_id" {
  description = "The project ID"
  value       = google_project.project.project_id
}

output "project_number" {
  description = "The numeric identifier of the project"
  value       = google_project.project.number
}

output "project_name" {
  description = "The display name of the project"
  value       = google_project.project.name
}
