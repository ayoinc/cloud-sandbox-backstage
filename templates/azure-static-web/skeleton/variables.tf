# =============================================================================
# Azure Static Web App - Root Variables
# =============================================================================

variable "name" {
  description = "Name of the Static Web App"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

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

variable "sku_tier" {
  description = "SKU tier (Free or Standard)"
  type        = string
  default     = "Free"
}

variable "framework" {
  description = "Frontend framework"
  type        = string
  default     = "react"
}

variable "enable_preview_environments" {
  description = "Enable preview environments"
  type        = bool
  default     = true
}

variable "enable_config_file_changes" {
  description = "Enable configuration file changes"
  type        = bool
  default     = true
}

variable "custom_domain" {
  description = "Custom domain name"
  type        = string
  default     = ""
}

variable "api_backend_resource_id" {
  description = "Resource ID of Azure Function for API backend"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
