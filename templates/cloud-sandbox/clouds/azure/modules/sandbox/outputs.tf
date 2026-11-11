output "resource_group_name" {
  description = "Name of the resource group that holds the sandbox."
  value       = azurerm_resource_group.this.name
}

output "vnet_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = azurerm_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = azurerm_subnet.private[*].id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion. Null when the bastion is not included."
  value       = one(azurerm_public_ip.bastion[*].ip_address)
}

output "bastion_ssh_private_key" {
  description = "Private SSH key of the bastion user `azureuser`. Null when the bastion is not included."
  value       = one(tls_private_key.bastion[*].private_key_openssh)
  sensitive   = true
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster. Null when AKS is not included."
  value       = one(azurerm_kubernetes_cluster.this[*].name)
}

output "postgresql_fqdn" {
  description = "Host name of the PostgreSQL server. Null when the database is not included."
  value       = one(azurerm_postgresql_flexible_server.this[*].fqdn)
}

output "postgresql_database_name" {
  description = "Name of the database. Null when the database is not included."
  value       = one(azurerm_postgresql_flexible_server_database.this[*].name)
}

output "postgresql_admin_password" {
  description = "Password of the PostgreSQL administrator `sandbox_admin`. Null when the database is not included."
  value       = one(random_password.postgresql[*].result)
  sensitive   = true
}
