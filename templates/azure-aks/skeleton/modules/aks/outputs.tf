# =============================================================================
# Azure AKS Module - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Resource Group Outputs
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# -----------------------------------------------------------------------------
# AKS Cluster Outputs
# -----------------------------------------------------------------------------

output "cluster_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_portal_fqdn" {
  description = "AKS cluster portal FQDN"
  value       = azurerm_kubernetes_cluster.main.portal_fqdn
}

output "kubernetes_version" {
  description = "Kubernetes version of the cluster"
  value       = azurerm_kubernetes_cluster.main.kubernetes_version
}

output "node_resource_group" {
  description = "Auto-generated resource group for AKS nodes"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

# -----------------------------------------------------------------------------
# Kubeconfig Outputs
# -----------------------------------------------------------------------------

output "kube_config" {
  description = "Kubeconfig for the cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_config_host" {
  description = "Kubernetes API server host"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

output "kube_config_client_certificate" {
  description = "Kubernetes client certificate"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
  sensitive   = true
}

output "kube_config_client_key" {
  description = "Kubernetes client key"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_key
  sensitive   = true
}

output "kube_config_cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Identity Outputs
# -----------------------------------------------------------------------------

output "kubelet_identity" {
  description = "Kubelet identity information"
  value = {
    client_id                 = azurerm_kubernetes_cluster.main.kubelet_identity[0].client_id
    object_id                 = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
    user_assigned_identity_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].user_assigned_identity_id
  }
}

output "identity_principal_id" {
  description = "Principal ID of the user-assigned identity"
  value       = azurerm_user_assigned_identity.aks.principal_id
}

output "identity_client_id" {
  description = "Client ID of the user-assigned identity"
  value       = azurerm_user_assigned_identity.aks.client_id
}

# -----------------------------------------------------------------------------
# Container Registry Outputs
# -----------------------------------------------------------------------------

output "acr_id" {
  description = "Container Registry ID"
  value       = var.create_acr ? azurerm_container_registry.main[0].id : null
}

output "acr_name" {
  description = "Container Registry name"
  value       = var.create_acr ? azurerm_container_registry.main[0].name : null
}

output "acr_login_server" {
  description = "Container Registry login server"
  value       = var.create_acr ? azurerm_container_registry.main[0].login_server : null
}

# -----------------------------------------------------------------------------
# Log Analytics Outputs
# -----------------------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics Workspace name"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_primary_key" {
  description = "Log Analytics Workspace primary shared key"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Node Pool Outputs
# -----------------------------------------------------------------------------

output "system_node_pool_name" {
  description = "Name of the system node pool"
  value       = "system"
}

output "user_node_pool_id" {
  description = "ID of the user node pool (if created)"
  value       = var.create_user_node_pool ? azurerm_kubernetes_cluster_node_pool.user[0].id : null
}

output "spot_node_pool_id" {
  description = "ID of the spot node pool (if created)"
  value       = var.create_spot_node_pool ? azurerm_kubernetes_cluster_node_pool.spot[0].id : null
}

# -----------------------------------------------------------------------------
# Helper Outputs
# -----------------------------------------------------------------------------

output "get_credentials_command" {
  description = "Azure CLI command to get kubectl credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "portal_url" {
  description = "Azure Portal URL for the AKS cluster"
  value       = "https://portal.azure.com/#resource${azurerm_kubernetes_cluster.main.id}/overview"
}

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------

output "cluster_info" {
  description = "Summary of AKS cluster configuration"
  value = {
    name                = azurerm_kubernetes_cluster.main.name
    id                  = azurerm_kubernetes_cluster.main.id
    resource_group      = azurerm_resource_group.main.name
    location            = azurerm_resource_group.main.location
    kubernetes_version  = azurerm_kubernetes_cluster.main.kubernetes_version
    fqdn                = azurerm_kubernetes_cluster.main.fqdn
    node_resource_group = azurerm_kubernetes_cluster.main.node_resource_group

    network = {
      plugin        = var.network_plugin
      policy        = var.network_policy
      outbound_type = var.outbound_type
    }

    node_pools = {
      system = {
        vm_size   = var.system_node_vm_size
        min_count = var.enable_auto_scaling ? var.system_min_count : var.system_node_count
        max_count = var.enable_auto_scaling ? var.system_max_count : var.system_node_count
      }
      user = var.create_user_node_pool ? {
        vm_size   = var.user_node_vm_size
        min_count = var.enable_auto_scaling ? var.user_min_count : var.user_node_count
        max_count = var.enable_auto_scaling ? var.user_max_count : var.user_node_count
      } : null
      spot = var.create_spot_node_pool ? {
        vm_size   = var.spot_node_vm_size
        max_count = var.spot_max_count
      } : null
    }

    acr = var.create_acr ? {
      name         = azurerm_container_registry.main[0].name
      login_server = azurerm_container_registry.main[0].login_server
    } : null
  }
}
