# Outputs of components that are not created are null (or an empty list).

output "network_id" {
  description = "Resource ID of the virtual network in use."
  value       = local.network_id
}

output "public_subnet_ids" {
  description = "Resource IDs of the public subnets."
  value       = local.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Resource IDs of the private subnets."
  value       = local.private_subnet_ids
}

output "kubernetes_cluster_name" {
  description = "Name of the AKS cluster."
  value       = one(azurerm_kubernetes_cluster.this[*].name)
}

output "kubernetes_cluster_endpoint" {
  description = "Host name of the Kubernetes API: the private name of a private cluster, the public name when kubernetes_api_allowed_cidrs is set."
  value       = !var.enable_kubernetes ? null : (length(var.kubernetes_api_allowed_cidrs) == 0 ? azurerm_kubernetes_cluster.this[0].private_fqdn : azurerm_kubernetes_cluster.this[0].fqdn)
}

output "database_endpoint" {
  description = "Host name (with port, or the URL for Cosmos DB for NoSQL) of the database."
  value       = local.database_endpoint
}

output "database_name" {
  description = "Name of the created database. Null for Redis."
  value       = var.enable_database && !local.redis_enabled ? local.database_name : null
}

output "database_credentials_secret_id" {
  description = "URI of the Key Vault secret with the database credentials. Null without a Key Vault and for Cosmos DB for NoSQL, which uses Microsoft Entra ID."
  value       = local.database_credentials_stored ? jsondecode(azurerm_resource_group_template_deployment.database_credentials[0].output_content).secretUri.value : null
}

output "database_password" {
  description = "Password or access key of the database. Null when it is stored in the Key Vault and for Cosmos DB for NoSQL."
  value       = local.database_credentials_stored ? null : local.database_password
  sensitive   = true
}

output "storage_bucket_name" {
  description = "Name of the storage account. Private blobs go to its content container."
  value       = one(azurerm_storage_account.this[*].name)
}

output "data_lake_bucket_names" {
  description = "Data lake file systems as <storage account>/<container>."
  value       = [for name in local.data_lake_containers : "${azurerm_storage_account.data_lake[0].name}/${azurerm_storage_container.data_lake[name].name}" if local.data_lake_enabled]
}

output "cdn_domain_name" {
  description = "Host name of the Front Door endpoint. It serves the cdn container of the storage account."
  value       = one(azurerm_cdn_frontdoor_endpoint.this[*].host_name)
}

output "waf_id" {
  description = "Resource ID of the web application firewall policy: a Front Door policy with a CDN, otherwise a regional policy for an Application Gateway."
  value       = local.waf_id
}

output "kms_key_id" {
  description = "Versionless URI of the customer-managed key."
  value       = local.kms_key_id
}

output "secrets_store_id" {
  description = "Resource ID of the Key Vault for secrets."
  value       = var.enable_secrets_manager ? azurerm_key_vault.this[0].id : null
}

output "container_registry_url" {
  description = "Login server of the container registry."
  value       = one(azurerm_container_registry.this[*].login_server)
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone of a networking-foundation stack."
  value       = one(azurerm_private_dns_zone.internal[*].name)
}

output "backup_vault_id" {
  description = "Resource ID of the backup vault."
  value       = one(azurerm_data_protection_backup_vault.this[*].id)
}

output "log_destination_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = one(azurerm_log_analytics_workspace.this[*].id)
}

output "alert_target_id" {
  description = "Resource ID of the action group that alerts notify."
  value       = one(azurerm_monitor_action_group.this[*].id)
}

output "prometheus_endpoint" {
  description = "Query endpoint of the Azure Monitor workspace for Prometheus metrics."
  value       = one(azurerm_monitor_workspace.this[*].query_endpoint)
}

output "grafana_endpoint" {
  description = "URL of the Azure Managed Grafana instance."
  value       = one(azurerm_dashboard_grafana.this[*].endpoint)
}
