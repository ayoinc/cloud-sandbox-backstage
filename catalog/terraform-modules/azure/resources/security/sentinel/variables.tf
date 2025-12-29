variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where resources will be created"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace to onboard to Sentinel"
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace"
  type        = string
}

variable "enable_aad_connector" {
  description = "Enable Azure Active Directory data connector"
  type        = bool
  default     = false
}

variable "enable_asc_connector" {
  description = "Enable Azure Security Center data connector"
  type        = bool
  default     = false
}

variable "enable_mcas_connector" {
  description = "Enable Microsoft Cloud App Security data connector"
  type        = bool
  default     = false
}

variable "enable_office365_connector" {
  description = "Enable Office 365 data connector"
  type        = bool
  default     = false
}

variable "enable_threat_intelligence_connector" {
  description = "Enable Threat Intelligence data connector"
  type        = bool
  default     = false
}

variable "office365_exchange_enabled" {
  description = "Enable Exchange logs in Office 365 connector"
  type        = bool
  default     = true
}

variable "office365_sharepoint_enabled" {
  description = "Enable SharePoint logs in Office 365 connector"
  type        = bool
  default     = true
}

variable "office365_teams_enabled" {
  description = "Enable Teams logs in Office 365 connector"
  type        = bool
  default     = true
}

variable "alert_rules" {
  description = "List of scheduled alert rules to create"
  type = list(object({
    name              = string
    display_name      = string
    severity          = string
    query             = string
    query_frequency   = string
    query_period      = string
    trigger_operator  = string
    trigger_threshold = number
    enabled           = bool
  }))
  default = []
}

variable "automation_rules" {
  description = "List of automation rules to create"
  type = list(object({
    name           = string
    display_name   = string
    order          = number
    condition_json = optional(string)
    action_incident = optional(object({
      order                  = number
      status                 = optional(string)
      classification         = optional(string)
      classification_comment = optional(string)
      labels                 = optional(list(string))
      owner_id               = optional(string)
      severity               = optional(string)
    }))
  }))
  default = []
}
