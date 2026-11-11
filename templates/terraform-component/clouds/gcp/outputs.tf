output "project_id" {
  description = "ID of the project the component is deployed into."
  value       = local.project_id
}

output "labels" {
  description = "Standard labels applied to every resource."
  value       = module.tagging.labels
}
