output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.id
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

# Additional outputs will be added based on resources created