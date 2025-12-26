output "resource_group_name" {
  description = "Resource group name"
  value       = module.infrastructure.azure_resource_group_name
}

output "vnet_id" {
  description = "VNet ID"
  value       = module.infrastructure.azure_vnet_id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value       = module.infrastructure.azure_subnet_ids
}
