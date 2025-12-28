# -----------------------------------------------------------------------------
# Azure Security Module - Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

# -----------------------------------------------------------------------------
# Key Vault Configuration
# -----------------------------------------------------------------------------

variable "key_vault_sku" {
  description = "SKU for the Key Vault (standard or premium)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku)
    error_message = "Key Vault SKU must be 'standard' or 'premium'."
  }
}

variable "enable_purge_protection" {
  description = "Enable purge protection for the Key Vault (recommended for production)"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted keys, secrets, and certificates"
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

variable "enabled_for_deployment" {
  description = "Allow Azure VMs to retrieve certificates stored as secrets"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Allow Azure Disk Encryption to retrieve secrets and unwrap keys"
  type        = bool
  default     = true
}

variable "enabled_for_template_deployment" {
  description = "Allow Azure Resource Manager to retrieve secrets"
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Enable RBAC authorization instead of access policies"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Key Vault Network ACLs
# -----------------------------------------------------------------------------

variable "network_acls" {
  description = "Network ACLs configuration for Key Vault"
  type = object({
    default_action             = string
    bypass                     = string
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
  })
  default = {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls.default_action)
    error_message = "Network ACLs default_action must be 'Allow' or 'Deny'."
  }

  validation {
    condition     = contains(["AzureServices", "None"], var.network_acls.bypass)
    error_message = "Network ACLs bypass must be 'AzureServices' or 'None'."
  }
}

# -----------------------------------------------------------------------------
# Encryption Key Configuration
# -----------------------------------------------------------------------------

variable "encryption_key_type" {
  description = "Type of the encryption key (RSA or EC)"
  type        = string
  default     = "RSA"

  validation {
    condition     = contains(["RSA", "RSA-HSM", "EC", "EC-HSM"], var.encryption_key_type)
    error_message = "Encryption key type must be RSA, RSA-HSM, EC, or EC-HSM."
  }
}

variable "encryption_key_size" {
  description = "Size of the encryption key in bits"
  type        = number
  default     = 2048

  validation {
    condition     = contains([2048, 3072, 4096], var.encryption_key_size)
    error_message = "Encryption key size must be 2048, 3072, or 4096."
  }
}

variable "key_rotation_time_before_expiry" {
  description = "Time before key expiry to trigger automatic rotation (ISO 8601 duration)"
  type        = string
  default     = "P30D"
}

variable "key_expiration_period" {
  description = "Key expiration period (ISO 8601 duration)"
  type        = string
  default     = "P365D"
}

variable "key_notify_before_expiry" {
  description = "Time before expiry to send notification (ISO 8601 duration)"
  type        = string
  default     = "P30D"
}

# -----------------------------------------------------------------------------
# Log Analytics Configuration
# -----------------------------------------------------------------------------

variable "log_analytics_sku" {
  description = "SKU for the Log Analytics workspace"
  type        = string
  default     = "PerGB2018"

  validation {
    condition     = contains(["Free", "PerNode", "Premium", "Standard", "Standalone", "Unlimited", "CapacityReservation", "PerGB2018"], var.log_analytics_sku)
    error_message = "Log Analytics SKU must be a valid SKU name."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics workspace"
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention days must be between 30 and 730."
  }
}

# -----------------------------------------------------------------------------
# Microsoft Defender Configuration
# -----------------------------------------------------------------------------

variable "enable_defender" {
  description = "Enable Microsoft Defender for Cloud (Security Center) pricing tiers"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Application Insights Configuration
# -----------------------------------------------------------------------------

variable "enable_application_insights" {
  description = "Enable Application Insights"
  type        = bool
  default     = false
}

variable "application_insights_type" {
  description = "Type of Application Insights"
  type        = string
  default     = "web"

  validation {
    condition     = contains(["ios", "java", "MobileCenter", "Node.JS", "other", "phone", "store", "web"], var.application_insights_type)
    error_message = "Application Insights type must be a valid application type."
  }
}

variable "application_insights_retention_days" {
  description = "Number of days to retain Application Insights data"
  type        = number
  default     = 90

  validation {
    condition     = contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.application_insights_retention_days)
    error_message = "Application Insights retention days must be one of: 30, 60, 90, 120, 180, 270, 365, 550, 730."
  }
}

variable "application_insights_sampling_percentage" {
  description = "Percentage of telemetry to sample (0-100)"
  type        = number
  default     = 100

  validation {
    condition     = var.application_insights_sampling_percentage >= 0 && var.application_insights_sampling_percentage <= 100
    error_message = "Sampling percentage must be between 0 and 100."
  }
}

variable "application_insights_disable_ip_masking" {
  description = "Disable IP masking in Application Insights"
  type        = bool
  default     = false
}

variable "application_insights_local_auth_disabled" {
  description = "Disable local authentication for Application Insights"
  type        = bool
  default     = true
}

variable "application_insights_internet_ingestion" {
  description = "Enable ingestion from public internet"
  type        = bool
  default     = true
}

variable "application_insights_internet_query" {
  description = "Enable querying from public internet"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
