{%- set aws = values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' -%}
{%- set azure = values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' -%}
{%- set gcp = values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' -%}
{%- set datadog = values.monitoring_solution == 'datadog' -%}
{%- set newrelic = values.monitoring_solution == 'new-relic' -%}
{%- set elastic = values.monitoring_solution == 'elastic-stack' -%}
output "name_prefix" {
  description = "Prefix of every resource name: the stack name and the short environment."
  value       = local.name_prefix
}

output "effective_settings" {
  description = "Settings after the compliance baseline and the dependencies between features are applied."
  value = {
    compliance_framework        = var.compliance_framework
    log_retention_days          = local.log_retention_days
    enable_kms                  = local.enable_kms
    enable_backup               = local.enable_backup
    enable_storage              = local.enable_storage
    require_deletion_protection = local.require_deletion_protection
    require_flow_logs           = local.compliance.require_flow_logs
  }
}
{%- if aws %}

# -----------------------------------------------------------------------------
# AWS
# -----------------------------------------------------------------------------

output "aws_network_id" {
  description = "ID of the network. Null or empty when it is not created."
  value       = module.aws.network_id
}

output "aws_public_subnet_ids" {
  description = "IDs of the public subnets. Null or empty when it is not created."
  value       = module.aws.public_subnet_ids
}

output "aws_private_subnet_ids" {
  description = "IDs of the private subnets. Null or empty when it is not created."
  value       = module.aws.private_subnet_ids
}

output "aws_kubernetes_cluster_name" {
  description = "Name of the Kubernetes cluster. Null or empty when it is not created."
  value       = module.aws.kubernetes_cluster_name
}

output "aws_database_endpoint" {
  description = "Endpoint of the database. Null or empty when it is not created."
  value       = module.aws.database_endpoint
}

output "aws_database_name" {
  description = "Name of the database. Null or empty when it is not created."
  value       = module.aws.database_name
}

output "aws_database_credentials_secret_id" {
  description = "ID of the secret that holds the generated database credentials. Null or empty when it is not created."
  value       = module.aws.database_credentials_secret_id
}

output "aws_storage_bucket_name" {
  description = "Name of the object storage bucket. Null or empty when it is not created."
  value       = module.aws.storage_bucket_name
}

output "aws_data_lake_bucket_names" {
  description = "Names of the data-lake buckets. Null or empty when it is not created."
  value       = module.aws.data_lake_bucket_names
}

output "aws_cdn_domain_name" {
  description = "Domain name of the CDN. Null or empty when it is not created."
  value       = module.aws.cdn_domain_name
}

output "aws_waf_id" {
  description = "ID of the web application firewall policy. Null or empty when it is not created."
  value       = module.aws.waf_id
}

output "aws_kms_key_id" {
  description = "ID of the customer-managed key. Null or empty when it is not created."
  value       = module.aws.kms_key_id
}

output "aws_secrets_store_id" {
  description = "ID of the secret store. Null or empty when it is not created."
  value       = module.aws.secrets_store_id
}

output "aws_container_registry_url" {
  description = "URL of the container registry. Null or empty when it is not created."
  value       = module.aws.container_registry_url
}

output "aws_private_dns_zone_name" {
  description = "Name of the private DNS zone. Null or empty when it is not created."
  value       = module.aws.private_dns_zone_name
}

output "aws_backup_vault_id" {
  description = "ID of the backup vault. Null or empty when it is not created."
  value       = module.aws.backup_vault_id
}

output "aws_log_destination_id" {
  description = "ID of the central log destination. Null or empty when it is not created."
  value       = module.aws.log_destination_id
}

output "aws_alert_target_id" {
  description = "ID of the notification target for alerts. Null or empty when it is not created."
  value       = module.aws.alert_target_id
}

output "aws_prometheus_endpoint" {
  description = "Endpoint of the managed Prometheus. Null or empty when it is not created."
  value       = module.aws.prometheus_endpoint
}

output "aws_grafana_endpoint" {
  description = "Endpoint of the managed Grafana. Null or empty when it is not created."
  value       = module.aws.grafana_endpoint
}

output "aws_database_password" {
  description = "Generated database password. Null when the credentials are kept in the secret store or the service has none."
  value       = module.aws.database_password
  sensitive   = true
}

output "aws_kubernetes_cluster_endpoint" {
  description = "Endpoint of the Kubernetes API. Null when the cluster is not created."
  value       = module.aws.kubernetes_cluster_endpoint
  sensitive   = true
}
{%- endif %}
{%- if azure %}

# -----------------------------------------------------------------------------
# Azure
# -----------------------------------------------------------------------------

output "azure_network_id" {
  description = "ID of the network. Null or empty when it is not created."
  value       = module.azure.network_id
}

output "azure_public_subnet_ids" {
  description = "IDs of the public subnets. Null or empty when it is not created."
  value       = module.azure.public_subnet_ids
}

output "azure_private_subnet_ids" {
  description = "IDs of the private subnets. Null or empty when it is not created."
  value       = module.azure.private_subnet_ids
}

output "azure_kubernetes_cluster_name" {
  description = "Name of the Kubernetes cluster. Null or empty when it is not created."
  value       = module.azure.kubernetes_cluster_name
}

output "azure_database_endpoint" {
  description = "Endpoint of the database. Null or empty when it is not created."
  value       = module.azure.database_endpoint
}

output "azure_database_name" {
  description = "Name of the database. Null or empty when it is not created."
  value       = module.azure.database_name
}

output "azure_database_credentials_secret_id" {
  description = "ID of the secret that holds the generated database credentials. Null or empty when it is not created."
  value       = module.azure.database_credentials_secret_id
}

output "azure_storage_bucket_name" {
  description = "Name of the object storage bucket. Null or empty when it is not created."
  value       = module.azure.storage_bucket_name
}

output "azure_data_lake_bucket_names" {
  description = "Names of the data-lake buckets. Null or empty when it is not created."
  value       = module.azure.data_lake_bucket_names
}

output "azure_cdn_domain_name" {
  description = "Domain name of the CDN. Null or empty when it is not created."
  value       = module.azure.cdn_domain_name
}

output "azure_waf_id" {
  description = "ID of the web application firewall policy. Null or empty when it is not created."
  value       = module.azure.waf_id
}

output "azure_kms_key_id" {
  description = "ID of the customer-managed key. Null or empty when it is not created."
  value       = module.azure.kms_key_id
}

output "azure_secrets_store_id" {
  description = "ID of the secret store. Null or empty when it is not created."
  value       = module.azure.secrets_store_id
}

output "azure_container_registry_url" {
  description = "URL of the container registry. Null or empty when it is not created."
  value       = module.azure.container_registry_url
}

output "azure_private_dns_zone_name" {
  description = "Name of the private DNS zone. Null or empty when it is not created."
  value       = module.azure.private_dns_zone_name
}

output "azure_backup_vault_id" {
  description = "ID of the backup vault. Null or empty when it is not created."
  value       = module.azure.backup_vault_id
}

output "azure_log_destination_id" {
  description = "ID of the central log destination. Null or empty when it is not created."
  value       = module.azure.log_destination_id
}

output "azure_alert_target_id" {
  description = "ID of the notification target for alerts. Null or empty when it is not created."
  value       = module.azure.alert_target_id
}

output "azure_prometheus_endpoint" {
  description = "Endpoint of the managed Prometheus. Null or empty when it is not created."
  value       = module.azure.prometheus_endpoint
}

output "azure_grafana_endpoint" {
  description = "Endpoint of the managed Grafana. Null or empty when it is not created."
  value       = module.azure.grafana_endpoint
}

output "azure_database_password" {
  description = "Generated database password. Null when the credentials are kept in the secret store or the service has none."
  value       = module.azure.database_password
  sensitive   = true
}

output "azure_kubernetes_cluster_endpoint" {
  description = "Endpoint of the Kubernetes API. Null when the cluster is not created."
  value       = module.azure.kubernetes_cluster_endpoint
  sensitive   = true
}
{%- endif %}
{%- if gcp %}

# -----------------------------------------------------------------------------
# Google Cloud
# -----------------------------------------------------------------------------

output "gcp_network_id" {
  description = "ID of the network. Null or empty when it is not created."
  value       = module.gcp.network_id
}

output "gcp_public_subnet_ids" {
  description = "IDs of the public subnets. Null or empty when it is not created."
  value       = module.gcp.public_subnet_ids
}

output "gcp_private_subnet_ids" {
  description = "IDs of the private subnets. Null or empty when it is not created."
  value       = module.gcp.private_subnet_ids
}

output "gcp_kubernetes_cluster_name" {
  description = "Name of the Kubernetes cluster. Null or empty when it is not created."
  value       = module.gcp.kubernetes_cluster_name
}

output "gcp_database_endpoint" {
  description = "Endpoint of the database. Null or empty when it is not created."
  value       = module.gcp.database_endpoint
}

output "gcp_database_name" {
  description = "Name of the database. Null or empty when it is not created."
  value       = module.gcp.database_name
}

output "gcp_database_credentials_secret_id" {
  description = "ID of the secret that holds the generated database credentials. Null or empty when it is not created."
  value       = module.gcp.database_credentials_secret_id
}

output "gcp_storage_bucket_name" {
  description = "Name of the object storage bucket. Null or empty when it is not created."
  value       = module.gcp.storage_bucket_name
}

output "gcp_data_lake_bucket_names" {
  description = "Names of the data-lake buckets. Null or empty when it is not created."
  value       = module.gcp.data_lake_bucket_names
}

output "gcp_cdn_domain_name" {
  description = "Domain name of the CDN. Null or empty when it is not created."
  value       = module.gcp.cdn_domain_name
}

output "gcp_waf_id" {
  description = "ID of the web application firewall policy. Null or empty when it is not created."
  value       = module.gcp.waf_id
}

output "gcp_kms_key_id" {
  description = "ID of the customer-managed key. Null or empty when it is not created."
  value       = module.gcp.kms_key_id
}

output "gcp_secrets_store_id" {
  description = "ID of the secret store. Null or empty when it is not created."
  value       = module.gcp.secrets_store_id
}

output "gcp_container_registry_url" {
  description = "URL of the container registry. Null or empty when it is not created."
  value       = module.gcp.container_registry_url
}

output "gcp_private_dns_zone_name" {
  description = "Name of the private DNS zone. Null or empty when it is not created."
  value       = module.gcp.private_dns_zone_name
}

output "gcp_backup_vault_id" {
  description = "ID of the backup vault. Null or empty when it is not created."
  value       = module.gcp.backup_vault_id
}

output "gcp_log_destination_id" {
  description = "ID of the central log destination. Null or empty when it is not created."
  value       = module.gcp.log_destination_id
}

output "gcp_alert_target_id" {
  description = "ID of the notification target for alerts. Null or empty when it is not created."
  value       = module.gcp.alert_target_id
}

output "gcp_prometheus_endpoint" {
  description = "Endpoint of the managed Prometheus. Null or empty when it is not created."
  value       = module.gcp.prometheus_endpoint
}

output "gcp_grafana_endpoint" {
  description = "Endpoint of the managed Grafana. Null or empty when it is not created."
  value       = module.gcp.grafana_endpoint
}

output "gcp_database_password" {
  description = "Generated database password. Null when the credentials are kept in the secret store or the service has none."
  value       = module.gcp.database_password
  sensitive   = true
}

output "gcp_kubernetes_cluster_endpoint" {
  description = "Endpoint of the Kubernetes API. Null when the cluster is not created."
  value       = module.gcp.kubernetes_cluster_endpoint
  sensitive   = true
}
{%- endif %}
{%- if elastic %}

# -----------------------------------------------------------------------------
# Elastic Stack
# -----------------------------------------------------------------------------

output "elastic_kibana_endpoint" {
  description = "URL of Kibana. Null when monitoring is off."
  value       = one(module.elastic[*].kibana_endpoint)
}

output "elastic_elasticsearch_endpoint" {
  description = "URL of Elasticsearch. Null when monitoring is off."
  value       = one(module.elastic[*].elasticsearch_endpoint)
}
{%- endif %}
