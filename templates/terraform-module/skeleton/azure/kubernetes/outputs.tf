# -----------------------------------------------------------------------------
# Azure Kubernetes Service (AKS) Module - Outputs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Cluster Outputs
# -----------------------------------------------------------------------------

output "cluster_id" {
  description = "The Azure Resource ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "The FQDN of the Azure Kubernetes Managed Cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_private_fqdn" {
  description = "The private FQDN of the Azure Kubernetes Managed Cluster (when private cluster is enabled)"
  value       = azurerm_kubernetes_cluster.main.private_fqdn
}

output "cluster_portal_fqdn" {
  description = "The Azure Portal FQDN for the cluster"
  value       = azurerm_kubernetes_cluster.main.portal_fqdn
}

# -----------------------------------------------------------------------------
# Kubernetes Configuration
# -----------------------------------------------------------------------------

output "kube_config" {
  description = "Kubernetes configuration object for provider configuration"
  value = {
    host                   = azurerm_kubernetes_cluster.main.kube_config[0].host
    client_certificate     = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
    client_key             = azurerm_kubernetes_cluster.main.kube_config[0].client_key
    cluster_ca_certificate = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
    username               = azurerm_kubernetes_cluster.main.kube_config[0].username
    password               = azurerm_kubernetes_cluster.main.kube_config[0].password
  }
  sensitive = true
}

output "kube_config_raw" {
  description = "Raw Kubernetes configuration file content (kubeconfig)"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_admin_config" {
  description = "Kubernetes admin configuration object (when Azure AD is enabled)"
  value = length(azurerm_kubernetes_cluster.main.kube_admin_config) > 0 ? {
    host                   = azurerm_kubernetes_cluster.main.kube_admin_config[0].host
    client_certificate     = azurerm_kubernetes_cluster.main.kube_admin_config[0].client_certificate
    client_key             = azurerm_kubernetes_cluster.main.kube_admin_config[0].client_key
    cluster_ca_certificate = azurerm_kubernetes_cluster.main.kube_admin_config[0].cluster_ca_certificate
    username               = azurerm_kubernetes_cluster.main.kube_admin_config[0].username
    password               = azurerm_kubernetes_cluster.main.kube_admin_config[0].password
  } : null
  sensitive = true
}

output "kube_admin_config_raw" {
  description = "Raw Kubernetes admin configuration file content (when Azure AD is enabled)"
  value       = azurerm_kubernetes_cluster.main.kube_admin_config_raw
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Identity Outputs
# -----------------------------------------------------------------------------

output "cluster_identity" {
  description = "User assigned identity for the AKS cluster"
  value = {
    id           = azurerm_user_assigned_identity.aks.id
    principal_id = azurerm_user_assigned_identity.aks.principal_id
    client_id    = azurerm_user_assigned_identity.aks.client_id
    tenant_id    = azurerm_user_assigned_identity.aks.tenant_id
  }
}

output "kubelet_identity" {
  description = "Kubelet identity for node pool operations"
  value = {
    client_id                 = azurerm_kubernetes_cluster.main.kubelet_identity[0].client_id
    object_id                 = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
    user_assigned_identity_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].user_assigned_identity_id
  }
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL for workload identity federation"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

# -----------------------------------------------------------------------------
# Network Outputs
# -----------------------------------------------------------------------------

output "node_resource_group" {
  description = "The auto-generated resource group containing AKS node resources"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "node_resource_group_id" {
  description = "The ID of the auto-generated resource group containing AKS node resources"
  value       = azurerm_kubernetes_cluster.main.node_resource_group_id
}

output "network_profile" {
  description = "Network profile configuration of the cluster"
  value = {
    network_plugin    = azurerm_kubernetes_cluster.main.network_profile[0].network_plugin
    network_policy    = azurerm_kubernetes_cluster.main.network_profile[0].network_policy
    dns_service_ip    = azurerm_kubernetes_cluster.main.network_profile[0].dns_service_ip
    service_cidr      = azurerm_kubernetes_cluster.main.network_profile[0].service_cidr
    pod_cidr          = azurerm_kubernetes_cluster.main.network_profile[0].pod_cidr
    outbound_type     = azurerm_kubernetes_cluster.main.network_profile[0].outbound_type
    load_balancer_sku = azurerm_kubernetes_cluster.main.network_profile[0].load_balancer_sku
  }
}

# -----------------------------------------------------------------------------
# Node Pool Outputs
# -----------------------------------------------------------------------------

output "default_node_pool_id" {
  description = "The ID of the default node pool"
  value       = "${azurerm_kubernetes_cluster.main.id}/agentPools/${var.default_node_pool.name}"
}

output "additional_node_pool_ids" {
  description = "Map of additional node pool names to their IDs"
  value       = { for k, v in azurerm_kubernetes_cluster_node_pool.additional : k => v.id }
}

# -----------------------------------------------------------------------------
# Add-on Outputs
# -----------------------------------------------------------------------------

output "key_vault_secrets_provider_identity" {
  description = "Identity for the Key Vault secrets provider (when enabled)"
  value = var.key_vault_secrets_provider_enabled && length(azurerm_kubernetes_cluster.main.key_vault_secrets_provider) > 0 ? {
    client_id                 = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].client_id
    object_id                 = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
    user_assigned_identity_id = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].user_assigned_identity_id
  } : null
}

output "oms_agent_identity" {
  description = "Identity for the OMS agent (Container Insights)"
  value = var.log_analytics_workspace_id != null && length(azurerm_kubernetes_cluster.main.oms_agent) > 0 ? {
    client_id                 = azurerm_kubernetes_cluster.main.oms_agent[0].oms_agent_identity[0].client_id
    object_id                 = azurerm_kubernetes_cluster.main.oms_agent[0].oms_agent_identity[0].object_id
    user_assigned_identity_id = azurerm_kubernetes_cluster.main.oms_agent[0].oms_agent_identity[0].user_assigned_identity_id
  } : null
}

# -----------------------------------------------------------------------------
# Version Information
# -----------------------------------------------------------------------------

output "kubernetes_version" {
  description = "The Kubernetes version running on the cluster"
  value       = azurerm_kubernetes_cluster.main.kubernetes_version
}

output "current_kubernetes_version" {
  description = "The current running Kubernetes version on the cluster"
  value       = azurerm_kubernetes_cluster.main.current_kubernetes_version
}
