# ==============================================================================
# Common Variables
# ==============================================================================

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "${{ values.name }}"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}

# ==============================================================================
# AWS Variables
# ==============================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  description = "CIDR block for the AWS VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
{%- endif %}

{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}

# ==============================================================================
# Azure Variables
# ==============================================================================

variable "azure_location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "azure_resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = ""
}

variable "azure_vnet_cidr" {
  description = "CIDR block for the Azure VNet"
  type        = string
  default     = "10.1.0.0/16"
}
{%- endif %}

{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}

# ==============================================================================
# GCP Variables
# ==============================================================================

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

variable "gcp_network_cidr" {
  description = "CIDR block for the GCP VPC"
  type        = string
  default     = "10.2.0.0/16"
}
{%- endif %}

# ==============================================================================
# Feature Flags
# ==============================================================================

variable "enable_compute" {
  description = "Enable compute resources"
  type        = bool
  default     = true
}

variable "enable_network" {
  description = "Enable network resources"
  type        = bool
  default     = true
}

variable "enable_storage" {
  description = "Enable storage resources"
  type        = bool
  default     = true
}

variable "enable_database" {
  description = "Enable database resources"
  type        = bool
  default     = false
}

variable "enable_security" {
  description = "Enable security resources"
  type        = bool
  default     = true
}

variable "enable_observability" {
  description = "Enable observability resources"
  type        = bool
  default     = true
}

variable "enable_kubernetes" {
  description = "Enable Kubernetes resources"
  type        = bool
  default     = false
}

variable "enable_serverless" {
  description = "Enable serverless resources"
  type        = bool
  default     = false
}
