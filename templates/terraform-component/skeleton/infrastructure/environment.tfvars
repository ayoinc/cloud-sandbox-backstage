# Environment-Specific Variables
# Each environment (dev/staging/prod) has isolated configuration

# Common variables across all environments
variable "project_name" {
  description = "Project name (used in resource naming)"
  type        = string
}

variable "component_name" {
  description = "Component name (used in resource naming)"
  type        = string
}

variable "environment" {
  description = "Environment name - matches Terraform workspace"
  type        = string
}

variable "region" {
  description = "Primary deployment region"
  type        = string
}

variable "secondary_region" {
  description = "Secondary region for disaster recovery"
  type        = string
  default     = null
}

variable "business_unit" {
  description = "Business unit or department"
  type        = string
  default     = "engineering"
}

variable "application_id" {
  description = "Unique application identifier (for app components)"
  type        = string
  default     = null
}

# Provider-specific configuration
{{- if eq .provider "aws" }}
variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}
{{- else if eq .provider "azure" }}
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}
{{- else if eq .provider "gcp" }}
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
}
{{- end }}

# Cost allocation tags (all environments)
variable "cost_center" {
  description = "Cost center for financial tracking"
  type        = string
}

# Default tags applied to all resources
locals {
  # Base tags (workspace-specific)
  base_tags = {
    Environment   = var.environment
    Project       = var.project_name
    Component     = var.component_name
    BusinessUnit  = var.business_unit
    CostCenter    = var.cost_center
    ManagedBy     = "terraform"
    TerraformWorkspace = terraform.workspace
    AutoShutdown  = var.environment == "development" ? "true" : "false"
  }

  # Additional tags for application components
  app_tags = var.application_id != null ? {
    ApplicationId = var.application_id
    Application   = var.project_name
  } : {}

  # Platform vs Application tags
  type_tags = var.component_type == "platform" ? {
    Tier      = "platform"
    Shared    = "true"
    Critical  = "true"
  } : {
    Tier      = "application"
    Shared    = "false"
  }

  # Environment-specific tags
  env_tags = {
    dev = {
      SLA         = "development"
      Backup      = "false"
      Monitoring  = "basic"
    }
    stg = {
      SLA         = "standard"
      Backup      = "true"
      Monitoring  = "standard"
    }
    prod = {
      SLA         = "critical"
      Backup      = "true"
      Monitoring  = "advanced"
      OnCall      = "true"
      DR          = "true"
    }
  }

  # Combined tags
  required_tags = merge(
    local.base_tags,
    local.app_tags,
    local.type_tags,
    lookup(local.env_tags, var.environment, {}),
    var.additional_tags
  )
}

# Optional additional tags
variable "additional_tags" {
  description = "Additional custom tags"
  type        = map(string)
  default     = {}
}
