variable "project_name" {
  description = "The name of the GCP project"
  type        = string
}

variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "project_iam_bindings" {
  description = "List of IAM bindings at the project level"
  type = list(object({
    role    = string
    members = list(string)
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = []
}

variable "custom_roles" {
  description = "List of custom IAM roles to create"
  type = list(object({
    role_id     = string
    title       = string
    description = optional(string)
    permissions = list(string)
    stage       = optional(string, "GA")
  }))
  default = []
}

variable "organization_id" {
  description = "The ID of the GCP organization (optional)"
  type        = string
  default     = null
}

variable "organization_iam_bindings" {
  description = "List of IAM bindings at the organization level"
  type = list(object({
    role    = string
    members = list(string)
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = []
}

variable "folder_id" {
  description = "The ID of the GCP folder (optional)"
  type        = string
  default     = null
}

variable "folder_iam_bindings" {
  description = "List of IAM bindings at the folder level"
  type = list(object({
    role    = string
    members = list(string)
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = []
}
