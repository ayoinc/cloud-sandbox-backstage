# =============================================================================
# Azure Full Infrastructure - Outputs
# =============================================================================
# Outputs of disabled modules are null.
# =============================================================================

# -----------------------------------------------------------------------------
# Resource Groups
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "Primary resource group name"
  value       = module.resource_group_primary.name
}

output "resource_group_id" {
  description = "Primary resource group ID"
  value       = module.resource_group_primary.id
}

output "network_resource_group_name" {
  description = "Networking resource group name"
  value       = var.enable_networking ? module.resource_group_network[0].name : null
}

output "security_resource_group_name" {
  description = "Security resource group name"
  value       = var.enable_security ? module.resource_group_security[0].name : null
}

output "monitoring_resource_group_name" {
  description = "Monitoring resource group name"
  value       = var.enable_monitoring ? module.resource_group_monitoring[0].name : null
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

output "vnet_id" {
  description = "Virtual network ID"
  value       = var.enable_networking ? module.networking[0].vnet_id : null
}

output "vnet_name" {
  description = "Virtual network name"
  value       = var.enable_networking ? module.networking[0].vnet_name : null
}

output "subnet_ids" {
  description = "Subnet IDs keyed by subnet name"
  value       = var.enable_networking ? module.networking[0].subnet_ids : {}
}

# -----------------------------------------------------------------------------
# Security and Identity
# -----------------------------------------------------------------------------

output "key_vault_id" {
  description = "Key Vault ID"
  value       = var.enable_security ? module.security[0].key_vault_id : null
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = var.enable_security ? module.security[0].key_vault_name : null
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = var.enable_security ? module.security[0].key_vault_uri : null
}

output "managed_identity_id" {
  description = "Managed identity resource ID"
  value       = var.enable_identity ? module.identity[0].managed_identity_id : null
}

output "managed_identity_client_id" {
  description = "Client ID of the managed identity"
  value       = var.enable_identity ? module.identity[0].managed_identity_client_id : null
}

output "managed_identity_principal_id" {
  description = "Principal (object) ID of the managed identity"
  value       = var.enable_identity ? module.identity[0].managed_identity_principal_id : null
}

# -----------------------------------------------------------------------------
# Storage
# -----------------------------------------------------------------------------

output "storage_account_name" {
  description = "Storage account name"
  value       = var.enable_storage ? module.storage[0].storage_account_name : null
}

output "storage_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = var.enable_storage ? module.storage[0].primary_blob_endpoint : null
}

output "storage_replication_type" {
  description = "Replication type of the storage account"
  value       = var.enable_storage ? module.storage[0].replication_type : null
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID"
  value       = var.enable_monitoring ? module.monitoring[0].workspace_id : null
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  value       = var.enable_monitoring ? module.monitoring[0].workspace_name : null
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = var.enable_monitoring ? module.monitoring[0].app_insights_connection_string : null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Containers
# -----------------------------------------------------------------------------

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = var.enable_containers ? module.containers[0].aks_cluster_name : null
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS API server"
  value       = var.enable_containers ? module.containers[0].aks_cluster_fqdn : null
}

output "acr_login_server" {
  description = "Container Registry login server"
  value       = var.enable_containers ? module.containers[0].acr_login_server : null
}

output "acr_sku" {
  description = "Container Registry SKU"
  value       = var.enable_containers ? module.containers[0].acr_sku : null
}

output "aks_get_credentials_command" {
  description = "Command that configures kubectl for the AKS cluster"
  value       = var.enable_containers ? "az aks get-credentials --resource-group ${module.resource_group_primary.name} --name ${module.containers[0].aks_cluster_name}" : null
}

# -----------------------------------------------------------------------------
# Database
# -----------------------------------------------------------------------------

output "database_server_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = var.enable_database ? module.database[0].server_fqdn : null
}

output "database_name" {
  description = "PostgreSQL database name"
  value       = var.enable_database ? module.database[0].database_name : null
}

output "database_administrator_login" {
  description = "PostgreSQL administrator login"
  value       = var.enable_database ? module.database[0].administrator_login : null
}

output "database_administrator_password" {
  description = "PostgreSQL administrator password"
  value       = var.enable_database ? module.database[0].administrator_password : null
  sensitive   = true
}

output "database_zone_redundant" {
  description = "Whether the PostgreSQL server has a zone-redundant standby"
  value       = var.enable_database ? module.database[0].zone_redundant : null
}

# -----------------------------------------------------------------------------
# Compute
# -----------------------------------------------------------------------------

output "vm_names" {
  description = "Virtual machine names"
  value       = var.enable_compute ? module.compute[0].vm_names : []
}

output "vm_private_ips" {
  description = "Private IP addresses of the virtual machines"
  value       = var.enable_compute ? module.compute[0].vm_private_ips : []
}

output "vm_auto_shutdown_enabled" {
  description = "Whether the virtual machines shut down daily"
  value       = var.enable_compute ? module.compute[0].auto_shutdown_enabled : false
}

output "vm_generated_ssh_private_key" {
  description = "Private key generated for the virtual machines (unused when admin_ssh_public_key is set)"
  value       = var.enable_compute ? module.compute[0].generated_ssh_private_key : null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Integration
# -----------------------------------------------------------------------------

output "service_bus_namespace_name" {
  description = "Service Bus namespace name"
  value       = var.enable_integration ? module.integration[0].service_bus_namespace_name : null
}

output "service_bus_endpoint" {
  description = "Service Bus endpoint"
  value       = var.enable_integration ? module.integration[0].service_bus_endpoint : null
}

output "event_grid_topic_endpoint" {
  description = "Event Grid topic endpoint"
  value       = var.enable_integration ? module.integration[0].event_grid_topic_endpoint : null
}

# -----------------------------------------------------------------------------
# Governance
# -----------------------------------------------------------------------------

output "budget_id" {
  description = "Budget ID"
  value       = var.enable_governance ? module.governance[0].budget_id : null
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

output "infrastructure_summary" {
  description = "Project, environment, regions and the modules that are enabled"
  value = {
    project            = var.name
    environment        = var.environment
    location           = var.location
    secondary_location = var.secondary_location
    disaster_recovery  = var.enable_dr
    high_availability  = var.enable_high_availability
    enabled_modules = {
      networking  = var.enable_networking
      compute     = var.enable_compute
      containers  = var.enable_containers
      storage     = var.enable_storage
      database    = var.enable_database
      security    = var.enable_security
      identity    = var.enable_identity
      monitoring  = var.enable_monitoring
      integration = var.enable_integration
      governance  = var.enable_governance
    }
  }
}
