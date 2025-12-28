# =============================================================================
# VARIABLES
# =============================================================================
# All variables for the Azure Full Infrastructure Stack
# Values are populated by Backstage template or terraform.tfvars
# =============================================================================

# -----------------------------------------------------------------------------
# Core Configuration
# -----------------------------------------------------------------------------

variable "azure_location" {
  description = "Primary Azure region for all resources"
  type        = string
  default     = "{{ primaryRegion }}"
}

variable "secondary_region" {
  description = "Secondary Azure region for DR"
  type        = string
  default     = "{{ secondaryRegion }}"
}

# -----------------------------------------------------------------------------
# Module Enable Flags
# -----------------------------------------------------------------------------

variable "enable_networking" {
  description = "Enable the Networking module"
  type        = bool
  default     = {{ enableNetworking }}
}

variable "enable_compute" {
  description = "Enable the Compute module"
  type        = bool
  default     = {{ enableCompute }}
}

variable "enable_containers" {
  description = "Enable the Containers module (AKS + ACR)"
  type        = bool
  default     = {{ enableContainers }}
}

variable "enable_storage" {
  description = "Enable the Storage module"
  type        = bool
  default     = {{ enableStorage }}
}

variable "enable_database" {
  description = "Enable the Database module"
  type        = bool
  default     = {{ enableDatabase }}
}

variable "enable_security" {
  description = "Enable the Security module"
  type        = bool
  default     = {{ enableSecurity }}
}

variable "enable_identity" {
  description = "Enable the Identity module"
  type        = bool
  default     = {{ enableIdentity }}
}

variable "enable_monitoring" {
  description = "Enable the Monitoring module"
  type        = bool
  default     = {{ enableMonitoring }}
}

variable "enable_integration" {
  description = "Enable the Integration module"
  type        = bool
  default     = {{ enableIntegration }}
}

variable "enable_governance" {
  description = "Enable the Governance module"
  type        = bool
  default     = {{ enableGovernance }}
}

# -----------------------------------------------------------------------------
# Advanced Features
# -----------------------------------------------------------------------------

variable "enable_dr" {
  description = "Enable Disaster Recovery features"
  type        = bool
  default     = {{ enableDR }}
}

variable "enable_high_availability" {
  description = "Enable High Availability configurations"
  type        = bool
  default     = {{ enableHighAvailability }}
}

variable "enable_auto_shutdown" {
  description = "Enable auto-shutdown for non-production resources"
  type        = bool
  default     = {{ enableAutoShutdown }}
}

variable "auto_shutdown_schedule" {
  description = "Cron schedule for auto-shutdown"
  type        = string
  default     = "{{ autoShutdownSchedule }}"
}

# -----------------------------------------------------------------------------
# Networking Configuration
# -----------------------------------------------------------------------------

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Map of subnet configurations"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
  }))
  default = {
    default = {
      address_prefixes = ["10.0.1.0/24"]
    }
    aks = {
      address_prefixes  = ["10.0.10.0/22"]
      service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.Storage"]
    }
    database = {
      address_prefixes  = ["10.0.20.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    }
    compute = {
      address_prefixes = ["10.0.30.0/24"]
    }
    private_endpoints = {
      address_prefixes = ["10.0.40.0/24"]
    }
  }
}

# -----------------------------------------------------------------------------
# AKS Configuration
# -----------------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.28"
}

variable "aks_node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 3
}

variable "aks_node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "aks_min_node_count" {
  description = "Minimum node count when auto-scaling is enabled"
  type        = number
  default     = 1
}

variable "aks_max_node_count" {
  description = "Maximum node count when auto-scaling is enabled"
  type        = number
  default     = 10
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------

variable "database_type" {
  description = "Type of database to create (sql, postgresql, mysql)"
  type        = string
  default     = "postgresql"

  validation {
    condition     = contains(["sql", "postgresql", "mysql"], var.database_type)
    error_message = "Database type must be one of: sql, postgresql, mysql."
  }
}

variable "database_sku_name" {
  description = "SKU name for the database"
  type        = string
  default     = "GP_Gen5_2"
}

variable "database_storage_mb" {
  description = "Storage size in MB for the database"
  type        = number
  default     = 32768
}

# -----------------------------------------------------------------------------
# Compute Configuration
# -----------------------------------------------------------------------------

variable "vm_size" {
  description = "Size of virtual machines"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "vm_count" {
  description = "Number of virtual machines to create"
  type        = number
  default     = 1
}

variable "os_type" {
  description = "Operating system type (linux, windows)"
  type        = string
  default     = "linux"

  validation {
    condition     = contains(["linux", "windows"], var.os_type)
    error_message = "OS type must be either 'linux' or 'windows'."
  }
}

# -----------------------------------------------------------------------------
# Governance Configuration
# -----------------------------------------------------------------------------

variable "monthly_budget" {
  description = "Monthly budget in USD for cost alerts"
  type        = number
  default     = 1000
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "{{ environment }}"

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stg, prod."
  }
}
