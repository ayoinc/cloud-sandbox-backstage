variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "name" {
  description = "The name of the diagnostic setting"
  type        = string
}

variable "target_resource_id" {
  description = "The ID of the resource to enable diagnostic settings on"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace to send diagnostics to"
  type        = string
  default     = null
}

variable "storage_account_id" {
  description = "The ID of the Storage Account to send diagnostics to"
  type        = string
  default     = null
}

variable "eventhub_authorization_rule_id" {
  description = "The ID of the Event Hub authorization rule to send diagnostics to"
  type        = string
  default     = null
}

variable "eventhub_name" {
  description = "The name of the Event Hub to send diagnostics to"
  type        = string
  default     = null
}

variable "partner_solution_id" {
  description = "The ID of the partner solution to send diagnostics to"
  type        = string
  default     = null
}

variable "enabled_logs" {
  description = "List of log categories to enable"
  type = list(object({
    category                 = optional(string)
    category_group           = optional(string)
    retention_policy_enabled = optional(bool)
    retention_policy_days    = optional(number)
  }))
  default = []
}

variable "metrics" {
  description = "List of metric categories to enable"
  type = list(object({
    category                 = string
    enabled                  = optional(bool, true)
    retention_policy_enabled = optional(bool)
    retention_policy_days    = optional(number)
  }))
  default = []
}

variable "log_analytics_destination_type" {
  description = "The destination type for Log Analytics. Possible values are 'Dedicated' or 'AzureDiagnostics'"
  type        = string
  default     = null

  validation {
    condition     = var.log_analytics_destination_type == null || contains(["Dedicated", "AzureDiagnostics"], var.log_analytics_destination_type)
    error_message = "log_analytics_destination_type must be either 'Dedicated' or 'AzureDiagnostics'"
  }
}
