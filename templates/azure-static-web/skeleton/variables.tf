variable "name" {
  description = "Name of the Static Web App"
  type        = string
  default     = "${{ values.name }}"
}

variable "description" {
  description = "Description of the app purpose"
  type        = string
  default     = "${{ values.description }}"
}

variable "environment" {
  description = "Environment (development, staging, production)"
  type        = string
  default     = "${{ values.environment }}"
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "${{ values.location }}"
}

variable "sku_tier" {
  description = "SKU tier (Free or Standard)"
  type        = string
  default     = "${{ values.skuTier }}"
}

variable "framework" {
  description = "Frontend framework"
  type        = string
  default     = "${{ values.framework }}"
}

variable "custom_domain" {
  description = "Custom domain name (requires Standard tier)"
  type        = string
  default     = ""
}

variable "api_backend_resource_id" {
  description = "Resource ID of Azure Function for API backend"
  type        = string
  default     = ""
}
