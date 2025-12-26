# Azure Module Outputs

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# VNet Outputs
output "vnet_id" {
  description = "ID of the VNet"
  value       = var.enable_networking ? azurerm_virtual_network.main.id : null
}

output "vnet_cidr" {
  description = "CIDR block of the VNet"
  value       = var.enable_networking ? azurerm_virtual_network.main.address_space[0] : null
}

# AKS Outputs
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = var.enable_kubernetes ? azurerm_kubernetes_cluster.main.name : null
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = var.enable_kubernetes ? azurerm_kubernetes_cluster.main.fqdn : null
}

output "aks_node_resource_group" {
  description = "Auto-generated resource group for AKS nodes"
  value       = var.enable_kubernetes ? azurerm_kubernetes_cluster.main.node_resource_group : null
}

output "kube_config" {
  description = "Kubernetes config"
  value       = var.enable_kubernetes ? azurerm_kubernetes_cluster.main.kube_config : null
  sensitive   = true
}

# Storage Outputs
output "storage_account_name" {
  description = "Name of the storage account"
  value       = var.enable_storage ? azurerm_storage_account.main.name : null
}

output "storage_account_primary_endpoint" {
  description = "Primary endpoint of the storage account"
  value       = var.enable_storage ? azurerm_storage_account.main.primary_blob_endpoint : null
}

# Database Outputs
output "postgresql_fqdn" {
  description = "PostgreSQL FQDN"
  value       = var.enable_database ? azurerm_postgresql_flexible_server.main.fqdn : null
  sensitive   = true
}

# Security Outputs
output "key_vault_id" {
  description = "Key Vault ID"
  value       = var.enable_key_vault ? azurerm_key_vault.main.id : null
}

output "key_vault_key_id" {
  description = "Key Vault key ID"
  value       = var.enable_key_vault ? azurerm_key_vault.main.id : null
}

# Networking Outputs
output "load_balancer_ip" {
  description = "Load balancer IP"
  value       = var.enable_kubernetes ? "pending" : null
}
