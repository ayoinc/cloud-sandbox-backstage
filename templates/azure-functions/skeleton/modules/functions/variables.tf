# =============================================================================
# Azure Functions Module - Input Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the Function App"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,59}[a-z0-9]$", var.name))
    error_message = "Name must be 3-61 characters, lowercase alphanumeric and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "development", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, development, production."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string

  validation {
    condition = contains([
      "westus2", "centralus", "eastus2", "westeurope", "eastasia", "australiaeast"
    ], var.location)
    error_message = "Location must be a supported Azure Functions region."
  }
}

# -----------------------------------------------------------------------------
# Optional Metadata
# -----------------------------------------------------------------------------

variable "description" {
  description = "Description of the Function App purpose"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Runtime Configuration
# -----------------------------------------------------------------------------

variable "runtime_stack" {
  description = "Runtime stack (dotnet, node, python, java)"
  type        = string
  default     = "node"

  validation {
    condition     = contains(["dotnet", "node", "python", "java"], var.runtime_stack)
    error_message = "Runtime stack must be one of: dotnet, node, python, java."
  }
}

variable "runtime_version" {
  description = "Version of the runtime stack"
  type        = string
  default     = "18"
}

# -----------------------------------------------------------------------------
# Hosting Configuration
# -----------------------------------------------------------------------------

variable "sku_tier" {
  description = "Hosting plan tier (Consumption, Premium, Dedicated)"
  type        = string
  default     = "Consumption"

  validation {
    condition     = contains(["Consumption", "Premium", "Dedicated"], var.sku_tier)
    error_message = "SKU tier must be 'Consumption', 'Premium', or 'Dedicated'."
  }
}

variable "storage_account_tier" {
  description = "Storage account tier (Standard, Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Storage account tier must be 'Standard' or 'Premium'."
  }
}

# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------

variable "enable_app_insights" {
  description = "Enable Application Insights for monitoring"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Application Settings
# -----------------------------------------------------------------------------

variable "app_settings" {
  description = "Additional application settings for the Function App"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# CORS Configuration
# -----------------------------------------------------------------------------

variable "cors_allowed_origins" {
  description = "List of allowed CORS origins"
  type        = list(string)
  default     = ["https://portal.azure.com"]
}

variable "cors_support_credentials" {
  description = "Support credentials in CORS"
  type        = bool
  default     = false
}
