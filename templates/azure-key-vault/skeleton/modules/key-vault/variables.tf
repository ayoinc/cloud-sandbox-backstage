# =============================================================================
# Azure Key Vault Module - Variables
# =============================================================================
# =============================================================================

variable "name" {
  description = "Name used in resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name))
    error_message = "The name must start with a letter and contain only lowercase letters, digits and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be dev, staging or prod."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "description" {
  description = "Purpose of the resources, added as a tag"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner of the resources, added as a tag"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Vault
# -----------------------------------------------------------------------------

variable "sku_name" {
  description = "Vault tier: standard, or premium for keys held in a hardware security module"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "The SKU must be standard or premium."
  }
}

variable "soft_delete_retention_days" {
  description = "Days a deleted vault, secret, key or certificate can be recovered. It cannot be changed after creation"
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "The soft delete retention must be between 7 and 90 days."
  }
}

variable "enabled_for_disk_encryption" {
  description = "Let Azure Disk Encryption read secrets and unwrap keys"
  type        = bool
  default     = false
}

variable "enabled_for_deployment" {
  description = "Let virtual machines read certificates stored as secrets"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Let Azure Resource Manager read secrets during deployments"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

variable "public_network_access_enabled" {
  description = "Keep the public endpoint. It stays behind the firewall: only allowed_ip_ranges and allowed_subnet_ids get through"
  type        = bool
  default     = false
}

variable "allowed_ip_ranges" {
  description = "Public IP addresses or CIDR ranges allowed through the firewall"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "Subnets (with the Microsoft.KeyVault service endpoint) allowed through the firewall"
  type        = list(string)
  default     = []
}

variable "trusted_services_bypass" {
  description = "Let trusted Azure services through the firewall. Needed when storage accounts, disks or databases are encrypted with keys in this vault"
  type        = bool
  default     = true
}

variable "private_endpoint_subnet_id" {
  description = "Subnet for a private endpoint to the vault; null creates none"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone privatelink.vaultcore.azure.net to register the private endpoint in; null registers nothing"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Access and Logging
# -----------------------------------------------------------------------------

variable "administrator_principal_ids" {
  description = "Object IDs granted Key Vault Administrator: manage every secret, key and certificate"
  type        = set(string)
  default     = []
}

variable "secrets_officer_principal_ids" {
  description = "Object IDs granted Key Vault Secrets Officer: create, change and delete secrets"
  type        = set(string)
  default     = []
}

variable "secrets_user_principal_ids" {
  description = "Object IDs granted Key Vault Secrets User: read secret values"
  type        = set(string)
  default     = []
}

variable "crypto_user_principal_ids" {
  description = "Object IDs granted Key Vault Crypto User: encrypt, decrypt, sign and verify with keys"
  type        = set(string)
  default     = []
}

variable "certificates_officer_principal_ids" {
  description = "Object IDs granted Key Vault Certificates Officer: create, change and delete certificates"
  type        = set(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace that receives the audit log; null sends none"
  type        = string
  default     = null
}
