# ==============================================================================
# Common Outputs
# ==============================================================================

output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}

# ==============================================================================
# AWS Outputs
# ==============================================================================

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = var.enable_network ? module.aws_network[0].vpc_id : null
}

output "aws_public_subnet_ids" {
  description = "AWS public subnet IDs"
  value       = var.enable_network ? module.aws_network[0].public_subnet_ids : []
}

output "aws_private_subnet_ids" {
  description = "AWS private subnet IDs"
  value       = var.enable_network ? module.aws_network[0].private_subnet_ids : []
}
{%- endif %}

{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}

# ==============================================================================
# Azure Outputs
# ==============================================================================

output "azure_location" {
  description = "Azure location"
  value       = var.azure_location
}

output "azure_resource_group_name" {
  description = "Azure resource group name"
  value       = local.azure_resource_group_name
}

output "azure_vnet_id" {
  description = "Azure VNet ID"
  value       = var.enable_network ? module.azure_network[0].vnet_id : null
}

output "azure_subnet_ids" {
  description = "Azure subnet IDs"
  value       = var.enable_network ? module.azure_network[0].subnet_ids : {}
}
{%- endif %}

{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}

# ==============================================================================
# GCP Outputs
# ==============================================================================

output "gcp_project_id" {
  description = "GCP project ID"
  value       = var.gcp_project_id
}

output "gcp_region" {
  description = "GCP region"
  value       = var.gcp_region
}

output "gcp_network_name" {
  description = "GCP VPC network name"
  value       = var.enable_network ? module.gcp_network[0].network_name : null
}

output "gcp_subnet_names" {
  description = "GCP subnet names"
  value       = var.enable_network ? module.gcp_network[0].subnet_names : []
}
{%- endif %}
