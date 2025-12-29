variable "project_name" {
  description = "Name of the project"
  type        = string

  validation {
    condition     = length(var.project_name) > 0
    error_message = "Project name must not be empty."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = length(var.environment) > 0
    error_message = "Environment must not be empty."
  }
}

variable "event_bus_name" {
  description = "Name of the custom event bus. If null, the default event bus is used"
  type        = string
  default     = null
}

variable "rules" {
  description = "List of EventBridge rules with their targets"
  type = list(object({
    name                = string
    description         = optional(string, "")
    schedule_expression = optional(string, null)
    event_pattern       = optional(string, null)
    state               = optional(string, "ENABLED")
    targets = list(object({
      id              = string
      arn             = string
      type            = string # lambda, sqs, sns, step_function
      input           = optional(string, null)
      input_path      = optional(string, null)
      role_arn        = optional(string, null)
      dead_letter_arn = optional(string, null)
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.rules : (
        rule.schedule_expression != null || rule.event_pattern != null
      )
    ])
    error_message = "Each rule must have either a schedule_expression or event_pattern."
  }

  validation {
    condition = alltrue([
      for rule in var.rules : contains(["ENABLED", "DISABLED"], rule.state)
    ])
    error_message = "Rule state must be either ENABLED or DISABLED."
  }

  validation {
    condition = alltrue([
      for rule in var.rules : alltrue([
        for target in rule.targets : contains(["lambda", "sqs", "sns", "step_function"], target.type)
      ])
    ])
    error_message = "Target type must be one of: lambda, sqs, sns, step_function."
  }
}

variable "enable_archive" {
  description = "Enable event archiving for the custom event bus"
  type        = bool
  default     = false
}

variable "archive_retention_days" {
  description = "Number of days to retain archived events. 0 means indefinite retention"
  type        = number
  default     = 0

  validation {
    condition     = var.archive_retention_days >= 0
    error_message = "Archive retention days must be 0 or greater."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
