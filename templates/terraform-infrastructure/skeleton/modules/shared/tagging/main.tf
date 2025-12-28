variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be dev, staging, prod, or test."
  }
}

variable "component" {
  description = "Component name"
  type        = string
  default     = ""
}

variable "managed_by" {
  description = "Managed by identifier"
  type        = string
  default     = "terraform"
}

variable "extra_tags" {
  description = "Additional custom tags"
  type        = map(string)
  default     = {}
}

locals {
  # Standard tags applied to all resources
  standard_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = var.managed_by
    Terraform   = "true"
    CreatedBy   = "backstage-devops-platform"
  }

  # Component tag if specified
  component_tag = var.component != "" ? { Component = var.component } : {}

  # Environment-specific tags
  environment_tags = {
    dev = {
      AutoShutdown = "true"
      CostCenter   = "development"
    }
    staging = {
      CostCenter = "staging"
    }
    prod = {
      BackupEnabled = "true"
      CostCenter    = "production"
    }
    test = {
      CostCenter = "testing"
    }
  }

  # Get environment-specific tags
  env_tags = lookup(local.environment_tags, var.environment, {})

  # Merge all tags
  all_tags = merge(
    local.standard_tags,
    local.component_tag,
    local.env_tags,
    var.extra_tags
  )
}

output "tags" {
  description = "Complete set of tags to apply to resources"
  value       = local.all_tags
}

output "labels" {
  description = "Tags formatted for GCP labels (lowercase, hyphens)"
  value = { for k, v in local.all_tags :
    replace(lower(k), "_", "-") => replace(lower(v), "_", "-")
  }
}