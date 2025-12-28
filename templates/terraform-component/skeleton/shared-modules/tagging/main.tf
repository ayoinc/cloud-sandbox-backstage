# Tagging Module
# Generates standardized tags for all cloud providers

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/stg/prod)"
  type        = string
}

variable "team" {
  description = "Team or department name"
  type        = string
  default     = "platform"
}

variable "cost_center" {
  description = "Cost center for financial tracking"
  type        = string
  default     = "engineering"
}

variable "application_id" {
  description = "Application ID (for app components)"
  type        = string
  default     = ""
}

variable "component_type" {
  description = "Component type (platform or application)"
  type        = string
  default     = "platform"
}

variable "additional_tags" {
  description = "Additional custom tags"
  type        = map(string)
  default     = {}
}

variable "auto_shutdown" {
  description = "Auto-shutdown schedule (for dev/stg)"
  type        = string
  default     = ""
}

locals {
  # Standard tags applied to all resources
  standard_tags = {
    # Project identification
    Project       = var.project
    Environment   = var.environment
    Team          = var.team
    CostCenter    = var.cost_center
    ManagedBy     = "terraform"
    AutoTerraform = "true"

    # Operational metadata
    AutoShutdown = length(var.auto_shutdown) > 0 ? "true" : "false"
  }

  # Auto-shutdown schedule (if specified)
  shutdown_tags = length(var.auto_shutdown) > 0 ? {
    AutoShutdownSchedule = var.auto_shutdown
  } : {}

  # Component classification tags
  type_tags = {
    ComponentType = var.component_type
    Shared        = var.component_type == "platform" ? "true" : "false"
    Critical      = var.environment == "prod" ? "true" : "false"
  }

  # Application-specific tags
  app_tags = length(var.application_id) > 0 ? {
    ApplicationId = var.application_id
  } : {}

  # Environment-specific operational tags
  env_metadata = {
    dev = {
      SLA        = "development"
      Backup     = "false"
      Monitoring = "basic"
      Support    = "business-hours"
    }
    stg = {
      SLA        = "standard"
      Backup     = "true"
      Monitoring = "standard"
      Support    = "business-hours"
    }
    prod = {
      SLA        = "critical"
      Backup     = "true"
      Monitoring = "advanced"
      Support    = "24x7"
      OnCall     = "true"
      DR         = "true"
    }
  }

  operational_tags = lookup(local.env_metadata, var.environment, {})

  # All tags merged
  all_tags = merge(
    local.standard_tags,
    local.shutdown_tags,
    local.type_tags,
    local.app_tags,
    local.operational_tags,
    var.additional_tags
  )
}

output "tags" {
  description = "Complete set of tags to apply to resources"
  value       = local.all_tags
}

output "standard_tags" {
  description = "Only standard tags (without custom additions)"
  value       = local.standard_tags
}

output "operational_tags" {
  description = "Operational metadata tags"
  value       = local.operational_tags
}