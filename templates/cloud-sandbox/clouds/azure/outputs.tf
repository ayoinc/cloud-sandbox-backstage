output "resource_group_name" {
  description = "Name of the resource group that holds the sandbox."
  value       = module.sandbox.resource_group_name
}

output "vnet_id" {
  description = "ID of the virtual network."
  value       = module.sandbox.vnet_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.sandbox.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.sandbox.private_subnet_ids
}

output "bastion_public_ip" {
  description = "Public IP of the bastion. Null when the bastion is not included."
  value       = module.sandbox.bastion_public_ip
}

output "bastion_ssh_private_key" {
  description = "Private SSH key of the bastion user `azureuser`. Null when the bastion is not included."
  value       = module.sandbox.bastion_ssh_private_key
  sensitive   = true
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster. Null when AKS is not included."
  value       = module.sandbox.aks_cluster_name
}

output "postgresql_fqdn" {
  description = "Host name of the PostgreSQL server. Null when the database is not included."
  value       = module.sandbox.postgresql_fqdn
}

output "postgresql_database_name" {
  description = "Name of the database. Null when the database is not included."
  value       = module.sandbox.postgresql_database_name
}

output "postgresql_admin_password" {
  description = "Password of the PostgreSQL administrator `sandbox_admin`. Null when the database is not included."
  value       = module.sandbox.postgresql_admin_password
  sensitive   = true
}
