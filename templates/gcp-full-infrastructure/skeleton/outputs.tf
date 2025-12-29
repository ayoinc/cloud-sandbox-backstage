# Resource Group
output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "resource_group_id" {
  value = azurerm_resource_group.main.id
}

# Networking
{%- if values.enable_networking %}
output "vnet_id" {
  value = module.networking.vnet_id
}

output "subnet_ids" {
  value = module.networking.subnet_ids
}
{%- endif %}

# Containers
{%- if values.enable_aks %}
output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "aks_kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}
{%- endif %}

{%- if values.enable_acr %}
output "acr_login_server" {
  value = module.acr.login_server
}
{%- endif %}

# Storage
{%- if values.enable_storage %}
output "storage_account_name" {
  value = module.storage.name
}
{%- endif %}

# Database
{%- if values.enable_sql %}
output "sql_server_fqdn" {
  value = module.sql.fqdn
}
{%- endif %}

{%- if values.enable_postgresql %}
output "postgresql_fqdn" {
  value = module.postgresql.fqdn
}
{%- endif %}

# Security
{%- if values.enable_keyvault %}
output "keyvault_uri" {
  value = module.keyvault.vault_uri
}
{%- endif %}

# Monitoring
{%- if values.enable_log_analytics %}
output "log_analytics_workspace_id" {
  value = module.monitoring.log_analytics_id
}
{%- endif %}
