# =============================================================================
# Azure AKS Module - Input Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the AKS cluster (used in resource naming)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "Name must be 3-63 characters, lowercase alphanumeric and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "development", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, development, production."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "Kubernetes version must be in format x.y.z (e.g., 1.28.3)."
  }
}

# -----------------------------------------------------------------------------
# Optional Metadata
# -----------------------------------------------------------------------------

variable "description" {
  description = "Description of the cluster purpose"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# System Node Pool Configuration
# -----------------------------------------------------------------------------

variable "system_node_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "system_node_count" {
  description = "Initial node count for system pool"
  type        = number
  default     = 2
}

variable "system_min_count" {
  description = "Minimum node count for system pool (autoscaling)"
  type        = number
  default     = 2
}

variable "system_max_count" {
  description = "Maximum node count for system pool (autoscaling)"
  type        = number
  default     = 5
}

# -----------------------------------------------------------------------------
# User Node Pool Configuration
# -----------------------------------------------------------------------------

variable "create_user_node_pool" {
  description = "Create a separate user node pool for workloads"
  type        = bool
  default     = true
}

variable "user_node_vm_size" {
  description = "VM size for user node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "user_node_count" {
  description = "Initial node count for user pool"
  type        = number
  default     = 2
}

variable "user_min_count" {
  description = "Minimum node count for user pool (autoscaling)"
  type        = number
  default     = 1
}

variable "user_max_count" {
  description = "Maximum node count for user pool (autoscaling)"
  type        = number
  default     = 10
}

variable "user_node_taints" {
  description = "Node taints for user node pool"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Spot Node Pool Configuration
# -----------------------------------------------------------------------------

variable "create_spot_node_pool" {
  description = "Create a spot node pool for cost savings"
  type        = bool
  default     = false
}

variable "spot_node_vm_size" {
  description = "VM size for spot node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "spot_node_count" {
  description = "Initial node count for spot pool"
  type        = number
  default     = 0
}

variable "spot_max_count" {
  description = "Maximum node count for spot pool"
  type        = number
  default     = 10
}

variable "spot_max_price" {
  description = "Maximum price for spot instances (-1 for on-demand price)"
  type        = number
  default     = -1
}

# -----------------------------------------------------------------------------
# Common Node Pool Settings
# -----------------------------------------------------------------------------

variable "enable_auto_scaling" {
  description = "Enable cluster autoscaler"
  type        = bool
  default     = true
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB for all node pools"
  type        = number
  default     = 128
}

variable "max_surge" {
  description = "Max surge for node pool upgrades"
  type        = string
  default     = "10%"
}

variable "availability_zones" {
  description = "Availability zones for node pools"
  type        = list(string)
  default     = ["1", "2", "3"]
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "network_plugin" {
  description = "Network plugin to use (azure or kubenet)"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "Network plugin must be 'azure' or 'kubenet'."
  }
}

variable "network_policy" {
  description = "Network policy to use (calico or azure)"
  type        = string
  default     = "calico"

  validation {
    condition     = contains(["calico", "azure", ""], var.network_policy)
    error_message = "Network policy must be 'calico', 'azure', or empty."
  }
}

variable "outbound_type" {
  description = "Outbound routing type (loadBalancer or userDefinedRouting)"
  type        = string
  default     = "loadBalancer"

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting"], var.outbound_type)
    error_message = "Outbound type must be 'loadBalancer' or 'userDefinedRouting'."
  }
}

variable "vnet_subnet_id" {
  description = "ID of the subnet to deploy AKS into (leave empty for AKS-managed VNet)"
  type        = string
  default     = ""
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP (must be within service_cidr)"
  type        = string
  default     = "10.0.0.10"
}

# -----------------------------------------------------------------------------
# Container Registry
# -----------------------------------------------------------------------------

variable "create_acr" {
  description = "Create an Azure Container Registry"
  type        = bool
  default     = true
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be 'Basic', 'Standard', or 'Premium'."
  }
}

variable "acr_georeplication_locations" {
  description = "Geo-replication locations for ACR (Premium SKU only)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Monitoring and Logging
# -----------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days."
  }
}

variable "enable_defender" {
  description = "Enable Microsoft Defender for Containers"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Security and Access Control
# -----------------------------------------------------------------------------

variable "enable_azure_rbac" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs for cluster admin access"
  type        = list(string)
  default     = []
}

variable "enable_workload_identity" {
  description = "Enable workload identity for pod-level Azure auth"
  type        = bool
  default     = true
}

variable "enable_secret_rotation" {
  description = "Enable automatic secret rotation from Key Vault"
  type        = bool
  default     = false
}

variable "secret_rotation_interval" {
  description = "Interval for secret rotation (e.g., 2m)"
  type        = string
  default     = "2m"
}

# -----------------------------------------------------------------------------
# Cluster Upgrade and Maintenance
# -----------------------------------------------------------------------------

variable "automatic_channel_upgrade" {
  description = "Automatic upgrade channel (none, patch, stable, rapid, node-image)"
  type        = string
  default     = "patch"

  validation {
    condition     = contains(["none", "patch", "stable", "rapid", "node-image"], var.automatic_channel_upgrade)
    error_message = "Automatic channel upgrade must be one of: none, patch, stable, rapid, node-image."
  }
}

variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    day   = string
    hours = list(number)
  })
  default = null
}

# -----------------------------------------------------------------------------
# Autoscaler Profile
# -----------------------------------------------------------------------------

variable "scale_down_delay_after_add" {
  description = "Delay after adding a node before considering scale down"
  type        = string
  default     = "10m"
}

variable "scale_down_unneeded" {
  description = "Time a node must be unneeded before scale down"
  type        = string
  default     = "10m"
}

variable "scale_down_utilization_threshold" {
  description = "Node utilization threshold below which to consider scale down"
  type        = string
  default     = "0.5"
}
