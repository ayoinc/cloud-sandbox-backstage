variable "name" {
  description = "Project name used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds the resources of this module"
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}

variable "grant_key_vault_access" {
  description = "Let the identity read secrets from key_vault_id"
  type        = bool
  default     = false
}

variable "key_vault_id" {
  description = "Key Vault the identity reads secrets from (used with grant_key_vault_access)"
  type        = string
  default     = null
}
