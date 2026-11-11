# -----------------------------------------------------------------------------
# Azure Security Module - Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,38}[a-z0-9]$", var.project_name))
    error_message = "Project name must be 2-40 characters of lowercase letters, numbers and hyphens, start with a letter and not end with a hyphen."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,11}$", var.environment))
    error_message = "Environment must be 2-12 lowercase letters or numbers and start with a letter."
  }
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
  description = "Key Vault firewall. The default denies everything except trusted Azure services; list the public IPs (ip_rules) and subnets (virtual_network_subnet_ids) that may reach the vault"
  type = object({
    default_action             = optional(string, "Deny")
    bypass                     = optional(string, "AzureServices")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  nullable = false
  default  = {}

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

variable "create_encryption_key" {
  description = "Create a customer-managed encryption key with automatic rotation. Keys are created through the vault data plane, so the machine running Terraform must be admitted by network_acls"
  type        = bool
  default     = false
}

variable "rbac_propagation_wait" {
  description = "Time to wait after granting Terraform access to the vault before creating the encryption key (role assignments are eventually consistent)"
  type        = string
  default     = "90s"

  validation {
    condition     = can(regex("^[0-9]+(s|m)$", var.rbac_propagation_wait))
    error_message = "Use a duration in seconds or minutes, for example 90s or 2m."
  }
}

variable "encryption_key_type" {
  description = "Type of the encryption key (RSA, RSA-HSM, EC or EC-HSM). HSM types need the premium vault SKU"
  type        = string
  default     = "RSA"

  validation {
    condition     = contains(["RSA", "RSA-HSM", "EC", "EC-HSM"], var.encryption_key_type)
    error_message = "Encryption key type must be RSA, RSA-HSM, EC, or EC-HSM."
  }
}

variable "encryption_key_curve" {
  description = "Elliptic curve for EC and EC-HSM keys"
  type        = string
  default     = "P-256"

  validation {
    condition     = contains(["P-256", "P-256K", "P-384", "P-521"], var.encryption_key_curve)
    error_message = "Encryption key curve must be P-256, P-256K, P-384 or P-521."
  }
}

variable "encryption_key_size" {
  description = "Size of RSA and RSA-HSM keys in bits"
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
  description = "Enable the Microsoft Defender for Cloud Standard tier for defender_resource_types. The setting is subscription-wide: enable it from one deployment per subscription only"
  type        = bool
  default     = false
}

variable "defender_resource_types" {
  description = "Resource types covered by Microsoft Defender for Cloud when enable_defender is true"
  type        = list(string)
  nullable    = false
  default     = ["Arm", "KeyVaults", "StorageAccounts"]

  validation {
    condition = alltrue([
      for resource_type in var.defender_resource_types : contains([
        "AI", "Api", "AppServices", "Arm", "CloudPosture", "ContainerRegistry", "Containers", "CosmosDbs", "Dns", "KeyVaults",
        "KubernetesService", "OpenSourceRelationalDatabases", "SqlServers", "SqlServerVirtualMachines", "StorageAccounts", "VirtualMachines",
      ], resource_type)
    ])
    error_message = "Each entry must be a Microsoft Defender for Cloud resource type such as Arm, KeyVaults, StorageAccounts, Containers or VirtualMachines."
  }
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
  nullable    = false
  default     = {}
}
