# Azure Security Module - Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "key_vaults" {
  description = "Map of Key Vaults to create"
  type = map(object({
    sku_name                        = optional(string, "standard")
    enabled_for_deployment          = optional(bool, false)
    enabled_for_disk_encryption     = optional(bool, false)
    enabled_for_template_deployment = optional(bool, false)
    enable_rbac_authorization       = optional(bool, true)
    purge_protection_enabled        = optional(bool, true)
    soft_delete_retention_days      = optional(number, 90)
    public_network_access_enabled   = optional(bool, true)
    network_acls = optional(object({
      bypass                     = optional(string, "AzureServices")
      default_action             = optional(string, "Allow")
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
    }))
  }))
  default = {}
}

variable "key_vault_access_policies" {
  description = "Map of Key Vault access policies (only used when RBAC is disabled)"
  type = map(object({
    key_vault_key           = string
    object_id               = string
    key_permissions         = optional(list(string), [])
    secret_permissions      = optional(list(string), [])
    certificate_permissions = optional(list(string), [])
    storage_permissions     = optional(list(string), [])
  }))
  default = {}
}

variable "key_vault_secrets" {
  description = "Map of Key Vault secrets to create"
  type = map(object({
    key_vault_key   = string
    value           = string
    content_type    = optional(string)
    expiration_date = optional(string)
    not_before_date = optional(string)
  }))
  default   = {}
  sensitive = true
}

variable "key_vault_keys" {
  description = "Map of Key Vault keys to create"
  type = map(object({
    key_vault_key   = string
    key_type        = string
    key_size        = optional(number)
    key_opts        = list(string)
    expiration_date = optional(string)
    not_before_date = optional(string)
    rotation_policy = optional(object({
      expire_after         = optional(string)
      notify_before_expiry = optional(string)
      automatic = optional(object({
        time_after_creation = optional(string)
        time_before_expiry  = optional(string)
      }))
    }))
  }))
  default = {}
}

variable "user_assigned_identities" {
  description = "Map of User Assigned Managed Identities to create"
  type        = map(object({}))
  default     = {}
}

variable "role_assignments" {
  description = "Map of Role Assignments to create"
  type = map(object({
    scope                = string
    role_definition_name = string
    principal_id         = optional(string)
    identity_key         = optional(string)
    principal_type       = optional(string, "ServicePrincipal")
  }))
  default = {}
}

variable "key_vault_private_endpoints" {
  description = "Map of Private Endpoints for Key Vaults"
  type = map(object({
    key_vault_key       = string
    subnet_id           = string
    private_dns_zone_id = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
