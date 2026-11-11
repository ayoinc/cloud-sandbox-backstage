output "resource_group_name" {
  description = "Name of the AWS resource group of this component. Null when it is not created."
  value       = one(aws_resourcegroups_group.this[*].name)
}

output "tags" {
  description = "Standard tags applied to every resource."
  value       = module.tagging.tags
}
