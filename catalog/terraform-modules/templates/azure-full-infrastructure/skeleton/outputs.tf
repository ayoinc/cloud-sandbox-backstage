# =============================================================================
# OUTPUTS
# =============================================================================
# All outputs from the Azure Full Infrastructure Stack
# =============================================================================

# -----------------------------------------------------------------------------
# Resource Group Outputs
# -----------------------------------------------------------------------------

output "resource_group_primary_id" {
  description = "ID of the primary resource group"
  value       = module.resource_group_primary.id
}

output "resource_group_primary_name" {
  description = "Name of the primary resource group"
  value       = module.resource_group_primary.name
}

output "resource_group_network_name" {
  description = "Name of the network resource group"
  value       = local.enable_network ? module.resource_group_network[0].name : null
}

output "resource_group_security_name" {
  description = "Name of the security resource group"
  value       = local.enable_security ? module.resource_group_security[0].name : null
}

output "resource_group_monitoring_name" {
  description = "Name of the monitoring resource group"
  value       = local.enable_monitoring ? module.resource_group_monitoring[0].name : null
}

# -----------------------------------------------------------------------------
# Networking Outputs
# -----------------------------------------------------------------------------

output "vnet_id" {
  description = "ID of the virtual network"
  value       = local.enable_network ? module.networking[0].vnet_id : null
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = local.enable_network ? module.networking[0].vnet_name : null
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = local.enable_network ? module.networking[0].subnet_ids : {}
}

# -----------------------------------------------------------------------------
# Security Outputs
# -----------------------------------------------------------------------------

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = local.enable_security ? module.security[0].key_vault_id : null
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = local.enable_security ? module.security[0].key_vault_name : null
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = local.enable_security ? module.security[0].key_vault_uri : null
}

# -----------------------------------------------------------------------------
# Storage Outputs
# -----------------------------------------------------------------------------

output "storage_account_id" {
  description = "ID of the storage account"
  value       = local.enable_storage ? module.storage[0].storage_account_id : null
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = local.enable_storage ? module.storage[0].storage_account_name : null
}

output "storage_primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = local.enable_storage ? module.storage[0].primary_blob_endpoint : null
}

# -----------------------------------------------------------------------------
# Monitoring Outputs
# -----------------------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = local.enable_monitoring ? module.monitoring[0].workspace_id : null
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = local.enable_monitoring ? module.monitoring[0].workspace_name : null
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = local.enable_monitoring ? module.monitoring[0].app_insights_connection_string : null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Container Outputs
# -----------------------------------------------------------------------------

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = local.enable_containers ? module.containers[0].aks_cluster_id : null
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = local.enable_containers ? module.containers[0].aks_cluster_name : null
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = local.enable_containers ? module.containers[0].aks_cluster_fqdn : null
}

output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = local.enable_containers ? module.containers[0].acr_id : null
}

output "acr_login_server" {
  description = "Login server for the Azure Container Registry"
  value       = local.enable_containers ? module.containers[0].acr_login_server : null
}

output "aks_kube_config" {
  description = "Kubernetes configuration for AKS"
  value       = local.enable_containers ? module.containers[0].kube_config : null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------

output "database_server_fqdn" {
  description = "FQDN of the database server"
  value       = local.enable_database ? module.database[0].server_fqdn : null
}

output "database_connection_string" {
  description = "Connection string for the database"
  value       = local.enable_database ? module.database[0].connection_string : null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Compute Outputs
# -----------------------------------------------------------------------------

output "vm_ids" {
  description = "IDs of the virtual machines"
  value       = local.enable_compute ? module.compute[0].vm_ids : []
}

output "vm_private_ips" {
  description = "Private IP addresses of the virtual machines"
  value       = local.enable_compute ? module.compute[0].vm_private_ips : []
}

# -----------------------------------------------------------------------------
# Identity Outputs
# -----------------------------------------------------------------------------

output "managed_identity_id" {
  description = "ID of the managed identity"
  value       = local.enable_identity ? module.identity[0].managed_identity_id : null
}

output "managed_identity_principal_id" {
  description = "Principal ID of the managed identity"
  value       = local.enable_identity ? module.identity[0].managed_identity_principal_id : null
}

output "managed_identity_client_id" {
  description = "Client ID of the managed identity"
  value       = local.enable_identity ? module.identity[0].managed_identity_client_id : null
}

# -----------------------------------------------------------------------------
# Integration Outputs
# -----------------------------------------------------------------------------

output "service_bus_namespace_id" {
  description = "ID of the Service Bus namespace"
  value       = local.enable_integration ? module.integration[0].service_bus_namespace_id : null
}

output "service_bus_connection_string" {
  description = "Connection string for Service Bus"
  value       = local.enable_integration ? module.integration[0].service_bus_connection_string : null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------

output "infrastructure_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    project     = local.project
    environment = local.environment
    location    = local.location
    enabled_modules = {
      networking  = local.enable_network
      compute     = local.enable_compute
      containers  = local.enable_containers
      storage     = local.enable_storage
      database    = local.enable_database
      security    = local.enable_security
      identity    = local.enable_identity
      monitoring  = local.enable_monitoring
      integration = local.enable_integration
      governance  = local.enable_governance
    }
    resource_groups = {
      primary    = module.resource_group_primary.name
      network    = local.enable_network ? module.resource_group_network[0].name : null
      security   = local.enable_security ? module.resource_group_security[0].name : null
      monitoring = local.enable_monitoring ? module.resource_group_monitoring[0].name : null
    }
  }
}
