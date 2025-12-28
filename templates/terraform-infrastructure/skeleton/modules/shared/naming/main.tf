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
}

variable "provider_type" {
  description = "Provider type (azure, aws, gcp, generic)"
  type        = string
  default     = "generic"
  validation {
    condition     = contains(["azure", "aws", "gcp", "generic"], var.provider_type)
    error_message = "Provider type must be azure, aws, gcp, or generic."
  }
}

variable "resource_type" {
  description = "Resource type (storage, compute, network, database, etc.)"
  type        = string
  default     = ""
}

locals {
  # Provider-specific naming conventions and constraints
  naming_rules = {
    azure = {
      max_length = 80
      separator  = "-"
      lowercase  = true
      # Azure specific constraints
      storage_max_length = 24
      storage_no_hyphens = true
    }
    aws = {
      max_length = 63
      separator  = "-"
      lowercase  = true
      # AWS specific constraints
      s3_max_length = 63
    }
    gcp = {
      max_length = 63
      separator  = "-"
      lowercase  = true
      # GCP specific constraints
      storage_max_length = 63
    }
    generic = {
      max_length = 64
      separator  = "-"
      lowercase  = true
    }
  }

  # Get naming rule for provider
  rule = local.naming_rules[var.provider_type]

  # Generate base name
  base_parts = compact([
    var.project,
    var.environment,
    var.component,
    var.resource_type
  ])
  
  base_name = join(local.rule.separator, local.base_parts)

  # Apply provider-specific transformations
  names = {
    azure = var.resource_type == "storage" ? 
      lower(replace(substr(local.base_name, 0, local.rule.storage_max_length), "-", "")) :
      lower(substr(local.base_name, 0, local.rule.max_length))
    
    aws = var.resource_type == "s3" ?
      lower(substr(local.base_name, 0, local.rule.s3_max_length)) :
      lower(substr(local.base_name, 0, local.rule.max_length))
    
    gcp = var.resource_type == "storage" ?
      lower(substr(local.base_name, 0, local.rule.storage_max_length)) :
      lower(substr(local.base_name, 0, local.rule.max_length))
    
    generic = substr(local.base_name, 0, local.rule.max_length)
  }
}

output "name" {
  description = "Generated resource name following naming conventions"
  value       = local.names[var.provider_type]
}

output "base_name" {
  description = "Base name before provider-specific transformations"
  value       = local.base_name
}

output "short_name" {
  description = "Short name for resources with strict length limits (24 chars)"
  value       = substr(local.base_name, 0, min(length(local.base_name), 24))
}

output "unique_name" {
  description = "Unique name with random suffix for global uniqueness"
  value       = "${local.names[var.provider_type]}-${substr(uuid(), 0, 8)}"
}