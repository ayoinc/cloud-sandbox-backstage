output "resource_group_name" {
  description = "Name of the resource group that holds the stack"
  value       = module.resource_group.name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.network.vnet_id
}

output "subnet_ids" {
  description = "IDs of the subnets by name"
  value       = module.network.subnet_ids
}

output "application_gateway_public_ip" {
  description = "Public address of the Application Gateway"
  value       = azurerm_public_ip.gateway.ip_address
}

output "application_gateway_identity_principal_id" {
  description = "Principal that needs the Key Vault Secrets User role on the vault holding tls_certificate_secret_id"
  value       = azurerm_user_assigned_identity.gateway.principal_id
}

output "application_url" {
  description = "Address the application is served at"
  value = (
    var.enable_front_door ? "https://${module.front_door[0].endpoint_host_names[local.name_prefix]}" :
    "${local.serves_https ? "https" : "http"}://${azurerm_public_ip.gateway.ip_address}"
  )
}

output "front_door_host_name" {
  description = "Host name of the Front Door endpoint, when enable_front_door is true"
  value       = one(module.front_door[*].endpoint_host_names[local.name_prefix])
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster (aks)"
  value       = one(azurerm_kubernetes_cluster.main[*].name)
}

output "aks_ingress_ip" {
  description = "Address the Application Gateway sends requests to. Give it to the internal load balancer of the cluster's ingress (aks)."
  value       = local.runs_aks ? local.aks_ingress_ip : null
}

output "aks_ingress_subnet_name" {
  description = "Subnet for the internal load balancer of the cluster's ingress (aks)"
  value       = local.runs_aks ? reverse(split("/", module.network.subnet_ids["ingress"]))[0] : null
}

output "vmss_name" {
  description = "Name of the virtual machine scale set (vmss)"
  value       = one(azurerm_linux_virtual_machine_scale_set.app[*].name)
}

output "vmss_admin_private_key" {
  description = "Generated SSH private key of the scale set administrator (vmss, while vmss_admin_ssh_public_key is null)"
  value       = one(tls_private_key.vmss[*].private_key_openssh)
  sensitive   = true
}

output "container_app_fqdn" {
  description = "Name of the Container App inside the virtual network (container-apps)"
  value       = one(azurerm_container_app.app[*].ingress[0].fqdn)
}

output "database_endpoint" {
  description = "Host name of the SQL or PostgreSQL server, or endpoint of the Cosmos DB account"
  value       = local.database_endpoint
}

output "database_name" {
  description = "Name of the database"
  value       = var.database_name
}

output "database_admin_username" {
  description = "Administrator login of the SQL or PostgreSQL server"
  value       = local.uses_cosmos ? null : var.database_admin_username
}

output "database_admin_password" {
  description = "Generated administrator password of the SQL or PostgreSQL server"
  value       = one(random_password.database[*].result)
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.log_analytics.workspace_id
}
