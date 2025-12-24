# =============================================================================
# Azure AKS - Root Outputs
# =============================================================================
# Expose all outputs from the child module.
# =============================================================================

# -----------------------------------------------------------------------------
# Resource Group Outputs
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.aks.resource_group_name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.aks.resource_group_id
}

# -----------------------------------------------------------------------------
# AKS Cluster Outputs
# -----------------------------------------------------------------------------

output "cluster_id" {
  description = "AKS cluster ID"
  value       = module.aks.cluster_id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks.cluster_fqdn
}

output "kubernetes_version" {
  description = "Kubernetes version"
  value       = module.aks.kubernetes_version
}

output "node_resource_group" {
  description = "Node resource group"
  value       = module.aks.node_resource_group
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL"
  value       = module.aks.oidc_issuer_url
}

# -----------------------------------------------------------------------------
# Kubeconfig Outputs
# -----------------------------------------------------------------------------

output "kube_config" {
  description = "Kubeconfig for the cluster"
  value       = module.aks.kube_config
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Identity Outputs
# -----------------------------------------------------------------------------

output "kubelet_identity" {
  description = "Kubelet identity"
  value       = module.aks.kubelet_identity
}

output "identity_principal_id" {
  description = "Identity principal ID"
  value       = module.aks.identity_principal_id
}

output "identity_client_id" {
  description = "Identity client ID"
  value       = module.aks.identity_client_id
}

# -----------------------------------------------------------------------------
# Container Registry Outputs
# -----------------------------------------------------------------------------

output "acr_id" {
  description = "Container Registry ID"
  value       = module.aks.acr_id
}

output "acr_name" {
  description = "Container Registry name"
  value       = module.aks.acr_name
}

output "acr_login_server" {
  description = "Container Registry login server"
  value       = module.aks.acr_login_server
}

# -----------------------------------------------------------------------------
# Log Analytics Outputs
# -----------------------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = module.aks.log_analytics_workspace_id
}

# -----------------------------------------------------------------------------
# Helper Outputs
# -----------------------------------------------------------------------------

output "get_credentials_command" {
  description = "Command to get kubectl credentials"
  value       = module.aks.get_credentials_command
}

output "portal_url" {
  description = "Azure Portal URL"
  value       = module.aks.portal_url
}

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------

output "cluster_info" {
  description = "Summary of AKS cluster configuration"
  value       = module.aks.cluster_info
}
