variable "name_prefix" {
  description = "Prefix for the names of all resources: up to 24 lowercase letters, digits and hyphens, starting with a letter."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,23}$", var.name_prefix))
    error_message = "name_prefix must be 1 to 24 characters of lowercase letters, digits and hyphens and start with a letter."
  }
}

variable "tags" {
  description = "Tags of the stack, sent to Datadog as account tags (key:value) on every metric of the project. Service accounts carry no labels."
  type        = map(string)
}

variable "project_id" {
  description = "ID of the Google Cloud project to monitor. null uses the project of the google provider configuration."
  type        = string
  default     = null
}
