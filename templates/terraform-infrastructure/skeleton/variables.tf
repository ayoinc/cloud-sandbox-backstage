# Variables for ${{ values.name }} Infrastructure

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "staging"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

variable "cloud_provider" {
  description = "Primary cloud provider"
  type        = string
  default     = "${{ values.cloud_provider }}"
  
  validation {
    condition     = contains(["aws", "azure", "gcp", "multi-cloud"], var.cloud_provider)
    error_message = "Cloud provider must be one of: aws, azure, gcp, multi-cloud."
  }
}

# AWS Variables
{% if values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' %}
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}
{% endif %}

# Azure Variables
{% if values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' %}
variable "azure_location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "vnet_cidr" {
  description = "CIDR block for VNet"
  type        = string
  default     = "10.1.0.0/16"
}
{% endif %}

# GCP Variables
{% if values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' %}
variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}
{% endif %}

# Infrastructure Feature Toggles
variable "enable_networking" {
  description = "Enable custom networking (VPC/VNet)"
  type        = bool
  default     = ${{ values.enable_networking }}
}

variable "enable_database" {
  description = "Enable managed database services"
  type        = bool
  default     = ${{ values.enable_database }}
}

variable "database_type" {
  description = "Type of database to deploy"
  type        = string
  default     = "${{ values.database_type }}"
  
  validation {
    condition     = contains(["postgresql", "mysql", "mongodb", "redis", "dynamodb", "cosmosdb"], var.database_type)
    error_message = "Database type must be one of: postgresql, mysql, mongodb, redis, dynamodb, cosmosdb."
  }
}

variable "enable_storage" {
  description = "Enable object storage"
  type        = bool
  default     = ${{ values.enable_storage }}
}

variable "enable_cdn" {
  description = "Enable CDN for content delivery"
  type        = bool
  default     = ${{ values.enable_cdn }}
}

# Kubernetes Variables
{% if values.enable_kubernetes %}
variable "enable_kubernetes" {
  description = "Enable managed Kubernetes cluster"
  type        = bool
  default     = ${{ values.enable_kubernetes }}
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "${{ values.kubernetes_version }}"
}

variable "node_instance_type" {
  description = "Instance type for Kubernetes nodes"
  type        = string
  default     = "${{ values.node_instance_type }}"
}

variable "enable_autoscaling" {
  description = "Enable cluster autoscaling"
  type        = bool
  default     = ${{ values.enable_autoscaling }}
}

variable "min_nodes" {
  description = "Minimum number of nodes"
  type        = number
  default     = ${{ values.min_nodes }}
  
  validation {
    condition     = var.min_nodes >= 1 && var.min_nodes <= 100
    error_message = "Min nodes must be between 1 and 100."
  }
}

variable "max_nodes" {
  description = "Maximum number of nodes"
  type        = number
  default     = ${{ values.max_nodes }}
  
  validation {
    condition     = var.max_nodes >= 1 && var.max_nodes <= 1000
    error_message = "Max nodes must be between 1 and 1000."
  }
}
{% endif %}

# Security Variables
variable "enable_security_group_rules" {
  description = "Enable security group/NSG rules"
  type        = bool
  default     = ${{ values.enable_security_group_rules }}
}

variable "enable_waf" {
  description = "Enable Web Application Firewall"
  type        = bool
  default     = ${{ values.enable_waf }}
}

variable "enable_secrets_manager" {
  description = "Enable secrets management service"
  type        = bool
  default     = ${{ values.enable_secrets_manager }}
}

variable "enable_kms" {
  description = "Enable Key Management Service"
  type        = bool
  default     = ${{ values.enable_kms }}
}

variable "enable_backup" {
  description = "Enable backup services"
  type        = bool
  default     = ${{ values.enable_backup }}
}

variable "compliance_framework" {
  description = "Target compliance framework"
  type        = string
  default     = "${{ values.compliance_framework }}"
  
  validation {
    condition     = contains(["none", "cis", "pci-dss", "hipaa", "sox", "gdpr"], var.compliance_framework)
    error_message = "Compliance framework must be one of: none, cis, pci-dss, hipaa, sox, gdpr."
  }
}

# Monitoring Variables
variable "enable_monitoring" {
  description = "Enable monitoring stack"
  type        = bool
  default     = ${{ values.enable_monitoring }}
}

variable "monitoring_solution" {
  description = "Monitoring platform to deploy"
  type        = string
  default     = "${{ values.monitoring_solution }}"
  
  validation {
    condition     = contains(["native", "prometheus-grafana", "elastic-stack", "datadog", "new-relic"], var.monitoring_solution)
    error_message = "Monitoring solution must be one of: native, prometheus-grafana, elastic-stack, datadog, new-relic."
  }
}

variable "enable_alerting" {
  description = "Enable alerting and notifications"
  type        = bool
  default     = ${{ values.enable_alerting }}
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = ${{ values.log_retention_days }}
  
  validation {
    condition     = contains([7, 30, 90, 365], var.log_retention_days)
    error_message = "Log retention must be one of: 7, 30, 90, 365 days."
  }
}

# Cost Optimization Variables
variable "enable_cost_optimization" {
  description = "Enable cost optimization features"
  type        = bool
  default     = ${{ values.enable_cost_optimization }}
}

variable "enable_disaster_recovery" {
  description = "Enable disaster recovery setup"
  type        = bool
  default     = ${{ values.enable_disaster_recovery }}
}

# Instance type mappings
locals {
  instance_type_mapping = {
    aws = {
      small  = "t3.medium"
      medium = "t3.large"
      large  = "t3.xlarge"
      xlarge = "t3.2xlarge"
    }
    azure = {
      small  = "Standard_D2s_v3"
      medium = "Standard_D4s_v3"
      large  = "Standard_D8s_v3"
      xlarge = "Standard_D16s_v3"
    }
    gcp = {
      small  = "e2-standard-2"
      medium = "e2-standard-4"
      large  = "e2-standard-8"
      xlarge = "e2-standard-16"
    }
  }
}

# Common tagging
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Environment-specific configurations
variable "environment_configs" {
  description = "Environment-specific configurations"
  type = map(object({
    node_count         = number
    instance_type      = string
    enable_monitoring  = bool
    backup_retention   = number
  }))
  
  default = {
    development = {
      node_count         = 2
      instance_type      = "small"
      enable_monitoring  = false
      backup_retention   = 7
    }
    staging = {
      node_count         = 3
      instance_type      = "medium"
      enable_monitoring  = true
      backup_retention   = 30
    }
    production = {
      node_count         = 5
      instance_type      = "large"
      enable_monitoring  = true
      backup_retention   = 90
    }
  }
}

# Network configuration
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access resources"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for services"
  type        = bool
  default     = true
}

variable "dns_zone_name" {
  description = "DNS zone name for the infrastructure"
  type        = string
  default     = "${{ values.name }}.company.com"
}
