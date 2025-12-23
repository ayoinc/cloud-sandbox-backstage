output "cluster_ids" {
  value = { for k, v in azurerm_kubernetes_cluster.this : k => v.id }
}

output "cluster_fqdns" {
  value = { for k, v in azurerm_kubernetes_cluster.this : k => v.fqdn }
}

output "cluster_private_fqdns" {
  value = { for k, v in azurerm_kubernetes_cluster.this : k => v.private_fqdn }
}

output "cluster_identities" {
  value = { for k, v in azurerm_kubernetes_cluster.this : k => {
    principal_id = v.identity[0].principal_id
    tenant_id    = v.identity[0].tenant_id
  } }
}

output "kubelet_identities" {
  value = { for k, v in azurerm_kubernetes_cluster.this : k => {
    client_id                 = v.kubelet_identity[0].client_id
    object_id                 = v.kubelet_identity[0].object_id
    user_assigned_identity_id = v.kubelet_identity[0].user_assigned_identity_id
  } }
}

output "oidc_issuer_urls" {
  value = { for k, v in azurerm_kubernetes_cluster.this : k => v.oidc_issuer_url }
}

output "node_resource_groups" {
  value = { for k, v in azurerm_kubernetes_cluster.this : k => v.node_resource_group }
}

output "kube_configs" {
  value     = { for k, v in azurerm_kubernetes_cluster.this : k => v.kube_config_raw }
  sensitive = true
}

output "node_pool_ids" {
  value = { for k, v in azurerm_kubernetes_cluster_node_pool.this : k => v.id }
}
