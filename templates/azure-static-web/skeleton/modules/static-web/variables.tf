# =============================================================================
# Azure Static Web App Module - Input Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the Static Web App"
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
    error_message = "Location must be a supported Static Web Apps region."
  }
}

# -----------------------------------------------------------------------------
# Optional Metadata
# -----------------------------------------------------------------------------

variable "description" {
  description = "Description of the app purpose"
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
# Static Web App Configuration
# -----------------------------------------------------------------------------

variable "sku_tier" {
  description = "SKU tier (Free or Standard)"
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "SKU tier must be 'Free' or 'Standard'."
  }
}

variable "framework" {
  description = "Frontend framework"
  type        = string
  default     = "react"

  validation {
    condition     = contains(["react", "vue", "angular", "nextjs", "gatsby", "hugo", "static"], var.framework)
    error_message = "Framework must be one of: react, vue, angular, nextjs, gatsby, hugo, static."
  }
}

variable "enable_preview_environments" {
  description = "Enable preview environments for pull requests"
  type        = bool
  default     = true
}

variable "enable_config_file_changes" {
  description = "Enable configuration file changes"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Custom Domain Configuration
# -----------------------------------------------------------------------------

variable "custom_domain" {
  description = "Custom domain name (requires Standard tier)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# API Backend Configuration
# -----------------------------------------------------------------------------

variable "api_backend_resource_id" {
  description = "Resource ID of Azure Function for API backend"
  type        = string
  default     = ""
}
