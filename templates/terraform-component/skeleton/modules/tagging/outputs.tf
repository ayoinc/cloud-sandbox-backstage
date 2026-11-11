output "tags" {
  description = "Standard tags for AWS and Azure resources."
  value       = local.tags
}

output "labels" {
  description = "The same tags as valid Google Cloud labels."
  value       = local.labels
}
