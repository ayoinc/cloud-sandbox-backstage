# Multi-Cloud Naming Standards
# Following each cloud provider's naming conventions

variable "project" {
  description = "Project or application name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "Environment must be dev, stg, or prod."
  }
}

variable "component" {
  description = "Component or service name"
  type        = string
}

variable "resource_type" {
  description = "Resource type (e.g., storage, compute, network)"
  type        = string
}

variable "instance" {
  description = "Instance number"
  type        = string
  default     = "001"
  validation {
    condition     = can(regex("^[0-9]{3}$", var.instance))
    error_message = "Instance must be a 3-digit number."
  }
}

variable "provider" {
  description = "Cloud provider (aws, azure, gcp)"
  type        = string
  validation {
    condition     = contains(["aws", "azure", "gcp"], var.provider)
    error_message = "Provider must be aws, azure, or gcp."
  }
}

variable "region" {
  description = "Region code (optional)"
  type        = string
  default     = ""
}

locals {
  # Provider-specific naming conventions
  naming_conventions = {
    aws = {
      # AWS: lowercase, hyphens, max 63 chars for most resources
      pattern    = "^[a-z0-9-]+$"
      max_length = 63
      separator  = "-"
      lowercase  = true
      # AWS-specific abbreviations
      abbreviations = {
        "storage"            = "s3"
        "compute"            = "ec2"
        "database"           = "rds"
        "container-registry" = "ecr"
        "virtual-network"    = "vpc"
        "security-group"     = "sg"
        "load-balancer"      = "lb"
        "key-management"     = "kms"
        "kubernetes"         = "eks"
        "lambda"             = "lambda"
        "dynamodb"           = "dynamo"
      }
    }
    azure = {
      # Azure: lowercase, hyphens, max lengths vary by resource
      pattern    = "^[a-z0-9-]+$"
      max_length = 80 # Most restrictive common limit
      separator  = "-"
      lowercase  = true
      # Azure-specific abbreviations
      abbreviations = {
        "storage"            = "st"
        "storage-account"    = "st"
        "compute"            = "vm"
        "database"           = "sql"
        "container-registry" = "cr"
        "virtual-network"    = "vnet"
        "security-group"     = "nsg"
        "load-balancer"      = "lb"
        "key-management"     = "kv"
        "kubernetes"         = "aks"
        "lambda"             = "func"
        "dynamodb"           = "cosmos"
      }
    }
    gcp = {
      # GCP: lowercase, hyphens, max 63 chars for most resources
      pattern    = "^[a-z0-9-]+$"
      max_length = 63
      separator  = "-"
      lowercase  = true
      # GCP-specific abbreviations
      abbreviations = {
        "storage"            = "gcs"
        "compute"            = "gce"
        "database"           = "sql"
        "container-registry" = "gcr"
        "virtual-network"    = "vpc"
        "security-group"     = "fw"
        "load-balancer"      = "lb"
        "key-management"     = "kms"
        "kubernetes"         = "gke"
        "lambda"             = "cf"
        "dynamodb"           = "datastore"
      }
    }
  }

  # Get provider-specific config
  provider_config = local.naming_conventions[var.provider]

  # Get abbreviated resource type
  abbreviated_type = lookup(
    local.provider_config.abbreviations,
    var.resource_type,
    substr(var.resource_type, 0, 4) # Default: first 4 chars
  )

  # Apply region code if provided
  region_part = var.region != "" ? var.region : null

  # Build base name
  base_name = join(
    local.provider_config.separator,
    compact([
      var.project,            # Project name (required)
      var.environment,        # Environment (dev/stg/prod)
      var.component,          # Component name
      local.abbreviated_type, # Abbreviated resource type
      region_part,            # Region (optional)
      var.instance            # Instance number
    ])
  )

  # Apply provider-specific transformation
  transformed_name = local.provider_config.lowercase ? lower(local.base_name) : local.base_name

  # Apply length limit
  final_name = substr(local.transformed_name, 0, min(length(local.transformed_name), local.provider_config.max_length))

  # Generate short name (for resources with strict limits)
  short_name = substr(local.final_name, 0, min(length(local.final_name), 24))

  # Generate unique name with hash (for global uniqueness)
  unique_suffix = substr(md5("${var.project}-${var.environment}-${var.component}-${timestamp()}"), 0, 8)
  unique_name   = "${local.final_name}-${local.unique_suffix}"
}

output "name" {
  description = "Resource name following provider naming conventions"
  value       = local.final_name
}

output "short_name" {
  description = "Short name for resources with strict limits"
  value       = local.short_name
}

output "unique_name" {
  description = "Globally unique name with hash suffix"
  value       = local.unique_name
}

output "full_name" {
  description = "Full name without truncation"
  value       = local.transformed_name
}

output "provider_config" {
  description = "Provider-specific naming configuration"
  value       = local.provider_config
  sensitive   = false
}