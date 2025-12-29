output "job_ids" {
  description = "Map of job names to their full resource IDs"
  value       = { for k, v in google_cloud_scheduler_job.job : k => v.id }
}

output "job_names" {
  description = "Map of job keys to their full resource names"
  value       = { for k, v in google_cloud_scheduler_job.job : k => v.name }
}
