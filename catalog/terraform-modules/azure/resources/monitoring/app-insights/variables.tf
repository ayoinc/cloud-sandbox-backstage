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
  description = "Azure region for the resources"
  type        = string
}

variable "name" {
  description = "Name of the Application Insights resource"
  type        = string
}

variable "application_type" {
  description = "Type of application being monitored"
  type        = string
  default     = "web"

  validation {
    condition     = contains(["web", "ios", "java", "MobileCenter", "Node.JS", "other", "phone", "store"], var.application_type)
    error_message = "application_type must be one of: web, ios, java, MobileCenter, Node.JS, other, phone, store."
  }
}

variable "workspace_id" {
  description = "Log Analytics Workspace ID for workspace-based Application Insights"
  type        = string
}

variable "retention_in_days" {
  description = "Number of days to retain data"
  type        = number
  default     = 90

  validation {
    condition     = contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.retention_in_days)
    error_message = "retention_in_days must be one of: 30, 60, 90, 120, 180, 270, 365, 550, 730."
  }
}

variable "daily_data_cap_in_gb" {
  description = "Daily data volume cap in GB (null for no cap)"
  type        = number
  default     = null
}

variable "daily_data_cap_notifications_disabled" {
  description = "Whether to disable notifications when data cap is reached"
  type        = bool
  default     = false
}

variable "sampling_percentage" {
  description = "Percentage of telemetry to collect (0-100)"
  type        = number
  default     = 100

  validation {
    condition     = var.sampling_percentage >= 0 && var.sampling_percentage <= 100
    error_message = "sampling_percentage must be between 0 and 100."
  }
}

variable "disable_ip_masking" {
  description = "Whether to disable IP masking"
  type        = bool
  default     = false
}

variable "local_authentication_disabled" {
  description = "Whether to disable local authentication (non-AAD based)"
  type        = bool
  default     = false
}

variable "web_tests" {
  description = "List of web tests for availability monitoring"
  type = list(object({
    name          = string
    url           = string
    frequency     = number
    timeout       = number
    geo_locations = list(string)
    enabled       = bool
  }))
  default = []

  validation {
    condition = alltrue([
      for test in var.web_tests : test.frequency >= 300 && test.frequency <= 900
    ])
    error_message = "Web test frequency must be between 300 and 900 seconds."
  }

  validation {
    condition = alltrue([
      for test in var.web_tests : test.timeout >= 30 && test.timeout <= 120
    ])
    error_message = "Web test timeout must be between 30 and 120 seconds."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
