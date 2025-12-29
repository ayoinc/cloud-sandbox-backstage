variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where the managed identity will be created"
  type        = string
}

variable "location" {
  description = "The Azure region where the managed identity will be created"
  type        = string
}

variable "identity_name" {
  description = "The name of the user-assigned managed identity"
  type        = string
}

variable "role_assignments" {
  description = "List of role assignments to create for the managed identity"
  type = list(object({
    scope                = string
    role_definition_name = string
  }))
  default = []
}

variable "federated_identity_credentials" {
  description = "List of federated identity credentials for workload identity federation"
  type = list(object({
    name      = string
    issuer    = string
    subject   = string
    audiences = list(string)
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to apply to the managed identity"
  type        = map(string)
  default     = {}
}
