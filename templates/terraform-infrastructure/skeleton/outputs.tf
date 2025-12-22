# Outputs for ${{ values.name }} Infrastructure

# General Information
output "infrastructure_name" {
  description = "Name of the infrastructure stack"
  value       = "${{ values.name }}"
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "cloud_provider" {
  description = "Primary cloud provider"
  value       = var.cloud_provider
}

{% if values.cloud_provider === 'aws' or values.cloud_provider === 'multi-cloud' %}
# AWS Outputs
output "aws_vpc_id" {
  description = "ID of the AWS VPC"
  value       = var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud" ? module.aws_infrastructure[0].vpc_id : null
}

output "aws_vpc_cidr" {
  description = "CIDR block of the AWS VPC"
  value       = var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud" ? module.aws_infrastructure[0].vpc_cidr : null
}

output "aws_private_subnet_ids" {
  description = "IDs of the AWS private subnets"
  value       = var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud" ? module.aws_infrastructure[0].private_subnet_ids : []
}

output "aws_public_subnet_ids" {
  description = "IDs of the AWS public subnets"
  value       = var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud" ? module.aws_infrastructure[0].public_subnet_ids : []
}

{% if values.enable_kubernetes %}
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = var.enable_kubernetes && (var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud") ? module.aws_infrastructure[0].eks_cluster_name : null
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = var.enable_kubernetes && (var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud") ? module.aws_infrastructure[0].eks_cluster_endpoint : null
  sensitive   = true
}

output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = var.enable_kubernetes && (var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud") ? module.aws_infrastructure[0].eks_cluster_version : null
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = var.enable_kubernetes && (var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud") ? module.aws_infrastructure[0].eks_cluster_arn : null
}

output "eks_node_group_arn" {
  description = "ARN of the EKS node group"
  value       = var.enable_kubernetes && (var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud") ? module.aws_infrastructure[0].eks_node_group_arn : null
}
{% endif %}

{% if values.enable_storage %}
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = var.enable_storage && (var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud") ? module.aws_infrastructure[0].s3_bucket_name : null
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = var.enable_storage && (var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud") ? module.aws_infrastructure[0].s3_bucket_arn : null
}
{% endif %}

{% if values.enable_database %}
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = var.enable_database && (var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud") ? module.aws_infrastructure[0].rds_endpoint : null
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = var.enable_database && (var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud") ? module.aws_infrastructure[0].rds_port : null
}
{% endif %}
{% endif %}

{% if values.cloud_provider === 'azure' or values.cloud_provider === 'multi-cloud' %}
# Azure Outputs
output "azure_resource_group_name" {
  description = "Name of the Azure resource group"
  value       = var.cloud_provider == "azure" || var.cloud_provider == "multi-cloud" ? module.azure_infrastructure[0].resource_group_name : null
}

output "azure_vnet_id" {
  description = "ID of the Azure VNet"
  value       = var.cloud_provider == "azure" || var.cloud_provider == "multi-cloud" ? module.azure_infrastructure[0].vnet_id : null
}

output "azure_vnet_cidr" {
  description = "CIDR block of the Azure VNet"
  value       = var.cloud_provider == "azure" || var.cloud_provider == "multi-cloud" ? module.azure_infrastructure[0].vnet_cidr : null
}

{% if values.enable_kubernetes %}
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = var.enable_kubernetes && (var.cloud_provider == "azure" || var.cloud_provider == "multi-cloud") ? module.azure_infrastructure[0].aks_cluster_name : null
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = var.enable_kubernetes && (var.cloud_provider == "azure" || var.cloud_provider == "multi-cloud") ? module.azure_infrastructure[0].aks_cluster_fqdn : null
}

output "aks_node_resource_group" {
  description = "Auto-generated resource group for AKS nodes"
  value       = var.enable_kubernetes && (var.cloud_provider == "azure" || var.cloud_provider == "multi-cloud") ? module.azure_infrastructure[0].aks_node_resource_group : null
}
{% endif %}

{% if values.enable_storage %}
output "azure_storage_account_name" {
  description = "Name of the Azure storage account"
  value       = var.enable_storage && (var.cloud_provider == "azure" || var.cloud_provider == "multi-cloud") ? module.azure_infrastructure[0].storage_account_name : null
}

output "azure_storage_account_primary_endpoint" {
  description = "Primary endpoint of the Azure storage account"
  value       = var.enable_storage && (var.cloud_provider == "azure" || var.cloud_provider == "multi-cloud") ? module.azure_infrastructure[0].storage_account_primary_endpoint : null
}
{% endif %}
{% endif %}

{% if values.cloud_provider === 'gcp' or values.cloud_provider === 'multi-cloud' %}
# GCP Outputs
output "gcp_project_id" {
  description = "GCP project ID"
  value       = var.cloud_provider == "gcp" || var.cloud_provider == "multi-cloud" ? var.gcp_project_id : null
}

output "gcp_vpc_network" {
  description = "Name of the GCP VPC network"
  value       = var.cloud_provider == "gcp" || var.cloud_provider == "multi-cloud" ? module.gcp_infrastructure[0].vpc_network : null
}

{% if values.enable_kubernetes %}
output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = var.enable_kubernetes && (var.cloud_provider == "gcp" || var.cloud_provider == "multi-cloud") ? module.gcp_infrastructure[0].gke_cluster_name : null
}

output "gke_cluster_endpoint" {
  description = "Endpoint for GKE cluster"
  value       = var.enable_kubernetes && (var.cloud_provider == "gcp" || var.cloud_provider == "multi-cloud") ? module.gcp_infrastructure[0].gke_cluster_endpoint : null
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "CA certificate for GKE cluster"
  value       = var.enable_kubernetes && (var.cloud_provider == "gcp" || var.cloud_provider == "multi-cloud") ? module.gcp_infrastructure[0].gke_cluster_ca_certificate : null
  sensitive   = true
}
{% endif %}

{% if values.enable_storage %}
output "gcs_bucket_name" {
  description = "Name of the GCS bucket"
  value       = var.enable_storage && (var.cloud_provider == "gcp" || var.cloud_provider == "multi-cloud") ? module.gcp_infrastructure[0].gcs_bucket_name : null
}

output "gcs_bucket_url" {
  description = "URL of the GCS bucket"
  value       = var.enable_storage && (var.cloud_provider == "gcp" || var.cloud_provider == "multi-cloud") ? module.gcp_infrastructure[0].gcs_bucket_url : null
}
{% endif %}
{% endif %}

{% if values.enable_monitoring %}
# Monitoring Outputs
output "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring stack"
  value       = var.enable_monitoring ? "monitoring" : null
}

{% if values.monitoring_solution === 'prometheus-grafana' %}
output "prometheus_endpoint" {
  description = "Prometheus server endpoint"
  value       = var.enable_monitoring && var.monitoring_solution == "prometheus-grafana" ? module.monitoring[0].prometheus_endpoint : null
}

output "grafana_endpoint" {
  description = "Grafana dashboard endpoint"
  value       = var.enable_monitoring && var.monitoring_solution == "prometheus-grafana" ? module.monitoring[0].grafana_endpoint : null
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.enable_monitoring && var.monitoring_solution == "prometheus-grafana" ? module.monitoring[0].grafana_admin_password : null
  sensitive   = true
}
{% endif %}
{% endif %}

{% if values.enable_secrets_manager %}
# Security Outputs
output "secrets_manager_arn" {
  description = "ARN of the secrets manager"
  value       = var.enable_secrets_manager ? (
    {% if values.cloud_provider === 'aws' %}
    var.cloud_provider == "aws" ? module.aws_infrastructure[0].secrets_manager_arn :
    {% endif %}
    {% if values.cloud_provider === 'azure' %}
    var.cloud_provider == "azure" ? module.azure_infrastructure[0].key_vault_id :
    {% endif %}
    {% if values.cloud_provider === 'gcp' %}
    var.cloud_provider == "gcp" ? module.gcp_infrastructure[0].secret_manager_id :
    {% endif %}
    null
  ) : null
}
{% endif %}

{% if values.enable_kms %}
output "kms_key_id" {
  description = "ID of the KMS key"
  value       = var.enable_kms ? (
    {% if values.cloud_provider === 'aws' %}
    var.cloud_provider == "aws" ? module.aws_infrastructure[0].kms_key_id :
    {% endif %}
    {% if values.cloud_provider === 'azure' %}
    var.cloud_provider == "azure" ? module.azure_infrastructure[0].key_vault_key_id :
    {% endif %}
    {% if values.cloud_provider === 'gcp' %}
    var.cloud_provider == "gcp" ? module.gcp_infrastructure[0].kms_key_id :
    {% endif %}
    null
  ) : null
}
{% endif %}

# Connection Information
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value = var.enable_kubernetes ? (
    {% if values.cloud_provider === 'aws' %}
    var.cloud_provider == "aws" ? "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.aws_infrastructure[0].eks_cluster_name}" :
    {% endif %}
    {% if values.cloud_provider === 'azure' %}
    var.cloud_provider == "azure" ? "az aks get-credentials --resource-group ${module.azure_infrastructure[0].resource_group_name} --name ${module.azure_infrastructure[0].aks_cluster_name}" :
    {% endif %}
    {% if values.cloud_provider === 'gcp' %}
    var.cloud_provider == "gcp" ? "gcloud container clusters get-credentials ${module.gcp_infrastructure[0].gke_cluster_name} --region ${var.gcp_region} --project ${var.gcp_project_id}" :
    {% endif %}
    null
  ) : null
}

# DNS and Networking
output "dns_zone_name" {
  description = "DNS zone name"
  value       = var.dns_zone_name
}

output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value = var.enable_kubernetes ? (
    {% if values.cloud_provider === 'aws' %}
    var.cloud_provider == "aws" ? module.aws_infrastructure[0].load_balancer_dns :
    {% endif %}
    {% if values.cloud_provider === 'azure' %}
    var.cloud_provider == "azure" ? module.azure_infrastructure[0].load_balancer_ip :
    {% endif %}
    {% if values.cloud_provider === 'gcp' %}
    var.cloud_provider == "gcp" ? module.gcp_infrastructure[0].load_balancer_ip :
    {% endif %}
    null
  ) : null
}

# Compliance and Security
output "compliance_framework" {
  description = "Applied compliance framework"
  value       = var.compliance_framework
}

output "backup_enabled" {
  description = "Whether backup is enabled"
  value       = var.enable_backup
}

# Cost Information
output "estimated_monthly_cost" {
  description = "Estimated monthly cost (approximate)"
  value = var.enable_cost_optimization ? (
    var.environment == "production" ? "$500-1500" :
    var.environment == "staging" ? "$200-600" :
    "$100-300"
  ) : "Cost optimization disabled"
}

# Quick Links
output "quick_links" {
  description = "Quick access links for common operations"
  value = {
    {% if values.cloud_provider === 'aws' %}
    aws_console = var.cloud_provider == "aws" ? "https://console.aws.amazon.com/" : null
    {% endif %}
    {% if values.cloud_provider === 'azure' %}
    azure_portal = var.cloud_provider == "azure" ? "https://portal.azure.com/" : null
    {% endif %}
    {% if values.cloud_provider === 'gcp' %}
    gcp_console = var.cloud_provider == "gcp" ? "https://console.cloud.google.com/" : null
    {% endif %}
    {% if values.enable_kubernetes %}
    kubernetes_dashboard = var.enable_kubernetes ? "https://dashboard.${{ values.name }}.company.com" : null
    {% endif %}
    {% if values.monitoring_solution === 'prometheus-grafana' %}
    grafana_dashboard = var.enable_monitoring ? "https://grafana.${{ values.name }}.company.com" : null
    {% endif %}
    terraform_cloud = "https://app.terraform.io/app/company-terraform/workspaces/${{ values.name }}"
  }
}

# Resource Summary
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    networking_enabled    = var.enable_networking
    kubernetes_enabled   = var.enable_kubernetes
    database_enabled     = var.enable_database
    storage_enabled      = var.enable_storage
    monitoring_enabled   = var.enable_monitoring
    security_features    = {
      kms_enabled           = var.enable_kms
      secrets_manager       = var.enable_secrets_manager
      waf_enabled          = var.enable_waf
      backup_enabled       = var.enable_backup
    }
    compliance_framework = var.compliance_framework
    cost_optimization   = var.enable_cost_optimization
  }
}
