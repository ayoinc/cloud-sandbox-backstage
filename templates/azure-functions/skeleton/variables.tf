# =============================================================================
# Azure Functions - Root Variables
# =============================================================================

variable "name" {
  description = "Name of the Function App"
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
  description = "Description of the Function App purpose"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = ""
}

variable "runtime_stack" {
  description = "Runtime stack (dotnet, node, python, java)"
  type        = string
  default     = "node"
}

variable "runtime_version" {
  description = "Version of the runtime stack"
  type        = string
  default     = "18"
}

variable "sku_tier" {
  description = "Hosting plan tier (Consumption, Premium, Dedicated)"
  type        = string
  default     = "Consumption"
}

variable "storage_account_tier" {
  description = "Storage account tier (Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "enable_app_insights" {
  description = "Enable Application Insights for monitoring"
  type        = bool
  default     = true
}

variable "app_settings" {
  description = "Additional application settings"
  type        = map(string)
  default     = {}
}

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

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
