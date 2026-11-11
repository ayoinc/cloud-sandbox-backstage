{%- set aws = values.provider == 'aws' or values.provider == 'multi-cloud' -%}
{%- set azure = values.provider == 'azure' or values.provider == 'multi-cloud' -%}
{%- set gcp = values.provider == 'gcp' or values.provider == 'multi-cloud' -%}
output "project_name" {
  description = "Project name the resources are named after."
  value       = module.platform.project_name
}
{%- if aws %}

output "aws_vpc_id" {
  description = "ID of the VPC."
  value       = module.platform.aws_vpc_id
}

output "aws_bucket_name" {
  description = "Name of the S3 bucket."
  value       = module.platform.aws_bucket_name
}
{%- endif %}
{%- if azure %}

output "azure_resource_group_name" {
  description = "Name of the resource group."
  value       = module.platform.azure_resource_group_name
}

output "azure_storage_account_name" {
  description = "Name of the storage account."
  value       = module.platform.azure_storage_account_name
}
{%- endif %}
{%- if gcp %}

output "gcp_network_name" {
  description = "Name of the VPC network."
  value       = module.platform.gcp_network_name
}

output "gcp_bucket_name" {
  description = "Name of the Cloud Storage bucket."
  value       = module.platform.gcp_bucket_name
}
{%- endif %}
