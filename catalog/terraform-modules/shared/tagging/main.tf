# =============================================================================
# SHARED TAGGING MODULE
# =============================================================================
# Standardized tagging/labeling for Azure, AWS, and GCP resources
# Supports environment isolation, compliance, and cost management
# =============================================================================

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "cloud_provider" {
  description = "Cloud provider: azure, aws, or gcp"
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "aws", "gcp"], var.cloud_provider)
    error_message = "Provider must be one of: azure, aws, gcp"
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "Environment must be dev, stg, or prod."
  }
}

variable "project" {
  description = "Project or application name"
  type        = string
}
variable "layer" {
  description = "Infrastructure layer"
  type        = string
  default     = "application"
  validation {
    condition     = contains(["platform", "application", "data", "network", "security", "monitoring"], var.layer)
    error_message = "Layer must be one of: platform, application, data, network, security, monitoring"
  }
}

variable "owner" {
  description = "Team or individual responsible for the resource"
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = ""
}

variable "department" {
  description = "Department that owns the resource"
  type        = string
  default     = ""
}

variable "data_classification" {
  description = "Data classification: public, internal, confidential, restricted"
  type        = string
  default     = "internal"
  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "Data classification must be one of: public, internal, confidential, restricted"
  }
}

variable "compliance" {
  description = "Compliance frameworks: none, pci, hipaa, sox, gdpr, iso27001"
  type        = list(string)
  default     = []
}

variable "backup_policy" {
  description = "Backup policy: none, daily, weekly, monthly"
  type        = string
  default     = "daily"
  validation {
    condition     = contains(["none", "daily", "weekly", "monthly"], var.backup_policy)
    error_message = "Backup policy must be one of: none, daily, weekly, monthly"
  }
}

variable "auto_shutdown" {
  description = "Enable auto-shutdown for non-prod environments"
  type        = bool
  default     = true
}

variable "shutdown_schedule" {
  description = "Auto-shutdown schedule (cron format)"
  type        = string
  default     = "0 20 * * 1-5" # 8 PM weekdays
}

variable "startup_schedule" {
  description = "Auto-startup schedule (cron format)"
  type        = string
  default     = "0 8 * * 1-5" # 8 AM weekdays
}

variable "created_by" {
  description = "Tool or process that created the resource"
  type        = string
  default     = "terraform"
}

variable "terraform_workspace" {
  description = "Terraform workspace name"
  type        = string
  default     = "default"
}

variable "repository" {
  description = "Source code repository URL"
  type        = string
  default     = ""
}

variable "pipeline" {
  description = "CI/CD pipeline URL or identifier"
  type        = string
  default     = ""
}

variable "expiration_date" {
  description = "Resource expiration date (ISO 8601 format)"
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional custom tags to merge"
  type        = map(string)
  default     = {}
}

variable "sensitive_tags" {
  description = "Tags that should be marked as sensitive"
  type        = map(string)
  default     = {}
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Locals - Tag Generation
# -----------------------------------------------------------------------------

locals {
  # Current timestamp for created_at tag
  timestamp = timestamp()
  date_only = formatdate("YYYY-MM-DD", local.timestamp)

  # Environment-specific settings
  is_production = var.environment == "prod"
  is_non_prod   = contains(["dev", "staging", "sandbox", "test", "uat"], var.environment)

  # Auto-shutdown only for non-prod
  enable_auto_shutdown = var.auto_shutdown && local.is_non_prod

  # Compliance tags as comma-separated string
  compliance_string = length(var.compliance) > 0 ? join(",", var.compliance) : "none"

  # Base required tags (present on all resources)
  required_tags = {
    Project            = var.project
    Environment        = var.environment
    Layer              = var.layer
    ManagedBy          = var.created_by
    DataClassification = var.data_classification
  }

  # Ownership tags
  ownership_tags = {
    Owner      = var.owner != "" ? var.owner : "unassigned"
    CostCenter = var.cost_center != "" ? var.cost_center : "default"
    Department = var.department != "" ? var.department : "engineering"
  }

  # Operational tags
  operational_tags = {
    BackupPolicy = var.backup_policy
    AutoShutdown = local.enable_auto_shutdown ? "enabled" : "disabled"
    Compliance   = local.compliance_string
  }

  # Scheduling tags (only for non-prod with auto-shutdown)
  scheduling_tags = local.enable_auto_shutdown ? {
    ShutdownSchedule = var.shutdown_schedule
    StartupSchedule  = var.startup_schedule
  } : {}

  # Audit/tracking tags
  audit_tags = {
    CreatedAt          = local.date_only
    TerraformWorkspace = var.terraform_workspace
    Repository         = var.repository != "" ? var.repository : "unknown"
    Pipeline           = var.pipeline != "" ? var.pipeline : "manual"
  }

  # Expiration tag (if set)
  expiration_tags = var.expiration_date != "" ? {
    ExpirationDate = var.expiration_date
  } : {}

  # Security tags
  security_tags = {
    SecurityZone = local.is_production ? "production" : "non-production"
  }

  # Merge all standard tags
  standard_tags = merge(
    local.required_tags,
    local.ownership_tags,
    local.operational_tags,
    local.scheduling_tags,
    local.audit_tags,
    local.expiration_tags,
    local.security_tags
  )

  # Final tags with additional custom tags (custom tags override standard)
  all_tags = merge(
    local.standard_tags,
    var.additional_tags,
    var.sensitive_tags
  )

  # GCP uses labels (lowercase keys, lowercase values, max 63 chars)
  gcp_labels = {
    for k, v in local.all_tags :
    lower(replace(k, "/[^a-z0-9_-]/", "_")) => lower(substr(replace(v, "/[^a-z0-9_-]/", "_"), 0, 63))
  }

  # AWS tags (key-value pairs, max 128 chars for key, 256 for value)
  aws_tags = {
    for k, v in local.all_tags :
    substr(k, 0, 128) => substr(v, 0, 256)
  }

  # Azure tags (max 512 chars for key, 256 for value)
  azure_tags = {
    for k, v in local.all_tags :
    substr(k, 0, 512) => substr(v, 0, 256)
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "tags" {
  description = "All tags as a map (provider-agnostic)"
  value       = local.all_tags
  sensitive   = true
}

output "azure_tags" {
  description = "Tags formatted for Azure resources"
  value       = local.azure_tags
  sensitive   = true
}

output "aws_tags" {
  description = "Tags formatted for AWS resources"
  value       = local.aws_tags
  sensitive   = true
}

output "gcp_labels" {
  description = "Labels formatted for GCP resources"
  value       = local.gcp_labels
  sensitive   = true
}

output "required_tags" {
  description = "Only the required/mandatory tags"
  value       = local.required_tags
  sensitive   = true
}

output "ownership_tags" {
  description = "Only ownership-related tags"
  value       = local.ownership_tags
  sensitive   = true
}

output "operational_tags" {
  description = "Only operational tags"
  value       = local.operational_tags
  sensitive   = true
}

output "is_production" {
  description = "Whether this is a production environment"
  value       = local.is_production
  sensitive   = true
}

output "auto_shutdown_enabled" {
  description = "Whether auto-shutdown is enabled"
  value       = local.enable_auto_shutdown
  sensitive   = true
}

output "tag_metadata" {
  description = "Full metadata about tagging configuration"
  value = {
    provider            = var.cloud_provider
    project             = var.project
    environment         = var.environment
    layer               = var.layer
    is_production       = local.is_production
    auto_shutdown       = local.enable_auto_shutdown
    data_classification = var.data_classification
    compliance          = var.compliance
    total_tags          = length(local.all_tags)
  }
  sensitive = true
}
