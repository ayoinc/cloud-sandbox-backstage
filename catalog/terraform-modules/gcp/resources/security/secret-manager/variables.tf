variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "secrets" {
  description = "List of secrets to create in Secret Manager"
  type = list(object({
    secret_id             = string
    replication_type      = string
    replication_locations = optional(list(string), [])
    kms_key_name          = optional(string)
    secret_data           = optional(string)
    iam_bindings = optional(list(object({
      role   = string
      member = string
    })), [])
  }))

  validation {
    condition = alltrue([
      for secret in var.secrets :
      contains(["automatic", "user_managed"], secret.replication_type)
    ])
    error_message = "replication_type must be either 'automatic' or 'user_managed'."
  }

  validation {
    condition = alltrue([
      for secret in var.secrets :
      secret.replication_type != "user_managed" || length(secret.replication_locations) > 0
    ])
    error_message = "replication_locations must be provided when replication_type is 'user_managed'."
  }
}

variable "labels" {
  description = "Additional labels to apply to secrets"
  type        = map(string)
  default     = {}
}
