variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "pricing_tier" {
  description = "Default pricing tier for Defender for Cloud"
  type        = string
  default     = "Standard"
}

variable "resource_type_pricing" {
  description = "Map of resource types to their pricing configuration"
  type = map(object({
    tier    = string
    subplan = optional(string)
  }))
  default = {
    VirtualMachines = {
      tier    = "Standard"
      subplan = "P2"
    }
    StorageAccounts = {
      tier    = "Standard"
      subplan = "DefenderForStorageV2"
    }
    SqlServers = {
      tier    = "Standard"
      subplan = null
    }
    AppServices = {
      tier    = "Standard"
      subplan = null
    }
    ContainerRegistry = {
      tier    = "Standard"
      subplan = null
    }
    KeyVaults = {
      tier    = "Standard"
      subplan = null
    }
    Dns = {
      tier    = "Standard"
      subplan = null
    }
    Arm = {
      tier    = "Standard"
      subplan = null
    }
    OpenSourceRelationalDatabases = {
      tier    = "Standard"
      subplan = null
    }
    Containers = {
      tier    = "Standard"
      subplan = null
    }
    CosmosDbs = {
      tier    = "Standard"
      subplan = null
    }
  }
}

variable "security_contact_email" {
  description = "Email address for security notifications"
  type        = string
}

variable "security_contact_phone" {
  description = "Phone number for security notifications"
  type        = string
  default     = null
}

variable "alert_notifications" {
  description = "Enable alert notifications to security contact"
  type        = bool
  default     = true
}

variable "alerts_to_admins" {
  description = "Send alerts to subscription admins"
  type        = bool
  default     = true
}

variable "auto_provisioning" {
  description = "Auto provisioning setting for Log Analytics agent"
  type        = string
  default     = "On"

  validation {
    condition     = contains(["On", "Off"], var.auto_provisioning)
    error_message = "Auto provisioning must be either 'On' or 'Off'."
  }
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for Defender for Cloud"
  type        = string
  default     = null
}

variable "enable_mcas_integration" {
  description = "Enable Microsoft Cloud App Security integration"
  type        = bool
  default     = false
}

variable "enable_wdatp_integration" {
  description = "Enable Windows Defender ATP integration"
  type        = bool
  default     = false
}
