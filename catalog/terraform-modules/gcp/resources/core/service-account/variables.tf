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

variable "account_id" {
  description = "The service account ID (must be 6-30 characters, lowercase letters, digits, hyphens)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.account_id))
    error_message = "The account_id must be 6-30 characters, start with a letter, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "display_name" {
  description = "The display name for the service account"
  type        = string
  default     = null
}

variable "description" {
  description = "A description of the service account"
  type        = string
  default     = null
}

variable "project_roles" {
  description = "List of IAM roles to grant to the service account at the project level"
  type        = list(string)
  default     = []
}

variable "create_key" {
  description = "Whether to create a service account key (not recommended for Workload Identity use cases)"
  type        = bool
  default     = false
}

variable "key_algorithm" {
  description = "The algorithm used to generate the key"
  type        = string
  default     = "KEY_ALG_RSA_2048"

  validation {
    condition     = contains(["KEY_ALG_RSA_1024", "KEY_ALG_RSA_2048"], var.key_algorithm)
    error_message = "The key_algorithm must be either KEY_ALG_RSA_1024 or KEY_ALG_RSA_2048."
  }
}

variable "impersonators" {
  description = "List of members and roles for service account impersonation"
  type = list(object({
    member = string
    role   = string
  }))
  default = []
}
