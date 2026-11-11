output "resource_group_name" {
  description = "Name of the resource group that holds the stack"
  value       = module.resource_group.name
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_id" {
  description = "Resource ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_kubernetes_version" {
  description = "Kubernetes version the cluster runs, including the patch release"
  value       = azurerm_kubernetes_cluster.main.current_kubernetes_version
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer of the cluster, for federated credentials of further workload identities"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "get_credentials_command" {
  description = "Command that adds the cluster to the local kubeconfig"
  value       = "az aks get-credentials --resource-group ${module.resource_group.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "node_resource_group_name" {
  description = "Resource group in which AKS keeps the nodes, load balancers and disks"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "node_vm_size" {
  description = "VM size of the nodes"
  value       = local.node_vm_sizes[var.node_size]
}

output "virtual_network_id" {
  description = "Resource ID of the virtual network"
  value       = module.network.vnet_id
}

output "node_subnet_id" {
  description = "Resource ID of the subnet of the nodes"
  value       = module.network.subnet_ids["aks"]
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace that receives the control plane logs"
  value       = module.log_analytics.workspace_id
}

output "external_dns_identity_client_id" {
  description = "Client ID of the managed identity of external-dns, when enable_external_dns is true"
  value       = one(module.external_dns_identity[*].client_id)
}

output "dns_zone_resource_group" {
  description = "Resource group whose Azure DNS zones external-dns manages"
  value       = local.dns_zone_resource_group
}
