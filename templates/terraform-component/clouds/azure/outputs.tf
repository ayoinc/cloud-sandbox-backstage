output "resource_group_name" {
  description = "Name of the resource group the component is deployed into."
  value       = local.resource_group_name
}

output "tags" {
  description = "Standard tags applied to every resource."
  value       = module.tagging.tags
}
