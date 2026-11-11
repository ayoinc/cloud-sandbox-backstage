{%- set aws = values.provider == 'aws' or values.provider == 'multi-cloud' -%}
{%- set azure = values.provider == 'azure' or values.provider == 'multi-cloud' -%}
{%- set gcp = values.provider == 'gcp' or values.provider == 'multi-cloud' -%}
output "project_name" {
  description = "Project name the resources are named after."
  value       = var.project_name
}

output "environment" {
  description = "Environment the resources belong to."
  value       = var.environment
}
{%- if aws %}

# -----------------------------------------------------------------------------
# AWS
# -----------------------------------------------------------------------------

output "aws_vpc_id" {
  description = "ID of the VPC. Null when the network is not created."
  value       = one(module.aws_network[*].vpc_id)
}

output "aws_public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = flatten(module.aws_network[*].public_subnet_ids)
}

output "aws_private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = flatten(module.aws_network[*].private_subnet_ids)
}

output "aws_kms_key_arn" {
  description = "ARN of the KMS key. Null when security is not created."
  value       = one(module.aws_security[*].kms_key_arn)
}

output "aws_bucket_name" {
  description = "Name of the S3 bucket. Null when storage is not created."
  value       = one(module.aws_storage[*].bucket_name)
}

output "aws_autoscaling_group_name" {
  description = "Name of the Auto Scaling group. Null when compute is not created."
  value       = one(module.aws_compute[*].autoscaling_group_name)
}

output "aws_db_endpoint" {
  description = "Endpoint of the RDS instance. Null when the database is not created."
  value       = one(module.aws_database[*].db_endpoint)
  sensitive   = true
}

output "aws_db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret with the database credentials. Null when the database is not created."
  value       = one(module.aws_database[*].db_credentials_secret_arn)
}

output "aws_eks_cluster_name" {
  description = "Name of the EKS cluster. Null when Kubernetes is not created."
  value       = one(module.aws_kubernetes[*].cluster_name)
}

output "aws_function_name" {
  description = "Name of the Lambda function. Null when serverless is not created."
  value       = one(module.aws_serverless[*].function_name)
}

output "aws_log_group_name" {
  description = "Name of the application log group. Null when observability is not created."
  value       = one(module.aws_observability[*].log_group_name)
}
{%- endif %}
{%- if azure %}

# -----------------------------------------------------------------------------
# Azure
# -----------------------------------------------------------------------------

output "azure_resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.main.name
}

output "azure_vnet_id" {
  description = "ID of the virtual network. Null when the network is not created."
  value       = one(module.azure_network[*].vnet_id)
}

output "azure_subnet_ids" {
  description = "Subnet IDs by tier: public, private, database, kubernetes. Null when the network is not created."
  value       = one(module.azure_network[*].subnet_ids)
}

output "azure_key_vault_name" {
  description = "Name of the Key Vault. Null when security is not created."
  value       = one(module.azure_security[*].key_vault_name)
}

output "azure_storage_account_name" {
  description = "Name of the storage account. Null when storage is not created."
  value       = one(module.azure_storage[*].storage_account_name)
}

output "azure_postgresql_server_fqdn" {
  description = "Host name of the PostgreSQL server. Null when the database is not created."
  value       = one(module.azure_database[*].postgresql_server_fqdn)
}

output "azure_aks_cluster_name" {
  description = "Name of the AKS cluster. Null when Kubernetes is not created."
  value       = one(module.azure_kubernetes[*].cluster_name)
}

output "azure_function_app_hostname" {
  description = "Default host name of the function app. Null when serverless is not created."
  value       = one(module.azure_serverless[*].function_app_default_hostname)
}

output "azure_log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace. Null when observability is not created."
  value       = one(module.azure_observability[*].log_analytics_workspace_id)
}
{%- endif %}
{%- if gcp %}

# -----------------------------------------------------------------------------
# Google Cloud
# -----------------------------------------------------------------------------

output "gcp_network_name" {
  description = "Name of the VPC network. Null when the network is not created."
  value       = one(module.gcp_network[*].network_name)
}

output "gcp_subnet_names" {
  description = "Names of the subnets."
  value       = flatten(module.gcp_network[*].subnet_names)
}

output "gcp_kms_key_id" {
  description = "ID of the Cloud KMS key. Null when security is not created."
  value       = one(module.gcp_security[*].kms_key_id)
}

output "gcp_bucket_name" {
  description = "Name of the Cloud Storage bucket. Null when storage is not created."
  value       = one(module.gcp_storage[*].bucket_name)
}

output "gcp_instance_group" {
  description = "Managed instance group. Null when compute is not created."
  value       = one(module.gcp_compute[*].instance_group)
}

output "gcp_sql_instance_name" {
  description = "Name of the Cloud SQL instance. Null when the database is not created."
  value       = one(module.gcp_database[*].instance_name)
}

output "gcp_sql_credentials_secret_id" {
  description = "ID of the Secret Manager secret with the database credentials. Null when the database is not created."
  value       = one(module.gcp_database[*].credentials_secret_id)
}

output "gcp_gke_cluster_name" {
  description = "Name of the GKE cluster. Null when Kubernetes is not created."
  value       = one(module.gcp_kubernetes[*].cluster_name)
}

output "gcp_service_url" {
  description = "URL of the serverless service. Null when serverless is not created."
  value       = one(module.gcp_serverless[*].service_url)
}

output "gcp_log_bucket_name" {
  description = "Name of the log archive bucket. Null when observability is not created."
  value       = one(module.gcp_observability[*].log_bucket_name)
}
{%- endif %}
