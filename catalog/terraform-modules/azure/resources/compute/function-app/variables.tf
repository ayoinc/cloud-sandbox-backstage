variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "function_app_name" {
  description = "Name of the function app"
  type        = string
}

variable "os_type" {
  description = "OS type for the function app (Linux or Windows)"
  type        = string
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "os_type must be either 'Linux' or 'Windows'."
  }
}

variable "sku_name" {
  description = "SKU name for the service plan (e.g., Y1 for consumption, EP1 for premium)"
  type        = string
  default     = "Y1"
}

variable "storage_account_name" {
  description = "Name of the storage account for the function app"
  type        = string
}

variable "storage_account_access_key" {
  description = "Access key for the storage account"
  type        = string
  sensitive   = true
}

variable "runtime_stack" {
  description = "Runtime stack for the function app (node, python, dotnet, java, powershell)"
  type        = string
  default     = "node"

  validation {
    condition     = contains(["node", "python", "dotnet", "java", "powershell"], var.runtime_stack)
    error_message = "runtime_stack must be one of: node, python, dotnet, java, powershell."
  }
}

variable "runtime_version" {
  description = "Version of the runtime stack"
  type        = string
  default     = "18"
}

variable "app_settings" {
  description = "Application settings for the function app"
  type        = map(string)
  default     = {}
}

variable "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  type        = string
  default     = null
}

variable "enable_system_identity" {
  description = "Enable system-assigned managed identity"
  type        = bool
  default     = true
}

variable "vnet_integration_subnet_id" {
  description = "Subnet ID for VNet integration"
  type        = string
  default     = null
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = []
}

variable "https_only" {
  description = "Force HTTPS only access"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
