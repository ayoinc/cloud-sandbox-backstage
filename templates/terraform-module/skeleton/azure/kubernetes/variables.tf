# -----------------------------------------------------------------------------
# Azure Kubernetes Service (AKS) Module - Variables
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

variable "vnet_id" {
  description = "Virtual Network ID (required for Network Contributor role assignment)"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
}

# -----------------------------------------------------------------------------
# Kubernetes Configuration
# -----------------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = null # Uses latest stable version if not specified
}

variable "automatic_upgrade_channel" {
  description = "Automatic upgrade channel (none, patch, rapid, stable, node-image)"
  type        = string
  default     = "stable"

  validation {
    condition     = contains(["none", "patch", "rapid", "stable", "node-image"], var.automatic_upgrade_channel)
    error_message = "automatic_upgrade_channel must be one of: none, patch, rapid, stable, node-image"
  }
}

variable "sku_tier" {
  description = "SKU tier for AKS cluster (Free or Standard)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "sku_tier must be either 'Free' or 'Standard'"
  }
}

variable "private_cluster_enabled" {
  description = "Enable private cluster (API server accessible only from private network)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Default Node Pool Configuration
# -----------------------------------------------------------------------------

variable "default_node_pool" {
  description = "Configuration for the default node pool"
  type = object({
    name                         = optional(string, "system")
    vm_size                      = optional(string, "Standard_D2s_v3")
    node_count                   = optional(number, 3)
    min_count                    = optional(number, 1)
    max_count                    = optional(number, 5)
    enable_auto_scaling          = optional(bool, true)
    max_pods                     = optional(number, 30)
    os_disk_size_gb              = optional(number, 128)
    os_disk_type                 = optional(string, "Managed")
    zones                        = optional(list(string), ["1", "2", "3"])
    only_critical_addons_enabled = optional(bool, false)
    max_surge                    = optional(string, "33%")
  })
  default = {}
}

# -----------------------------------------------------------------------------
# Additional Node Pools Configuration
# -----------------------------------------------------------------------------

variable "additional_node_pools" {
  description = "List of additional node pools to create"
  type = list(object({
    name                = string
    vm_size             = optional(string, "Standard_D2s_v3")
    node_count          = optional(number, 1)
    min_count           = optional(number, 0)
    max_count           = optional(number, 5)
    enable_auto_scaling = optional(bool, true)
    max_pods            = optional(number, 30)
    os_disk_size_gb     = optional(number, 128)
    os_disk_type        = optional(string, "Managed")
    os_type             = optional(string, "Linux")
    zones               = optional(list(string), ["1", "2", "3"])
    priority            = optional(string, "Regular")
    eviction_policy     = optional(string, "Delete")
    spot_max_price      = optional(number, -1)
    mode                = optional(string, "User")
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
    max_surge           = optional(string, "33%")
  }))
  default = []
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
    error_message = "network_plugin must be either 'azure' or 'kubenet'"
  }
}

variable "network_plugin_mode" {
  description = "Network plugin mode (only applicable when network_plugin is 'azure')"
  type        = string
  default     = null

  validation {
    condition     = var.network_plugin_mode == null || var.network_plugin_mode == "overlay"
    error_message = "network_plugin_mode must be null or 'overlay'"
  }
}

variable "network_policy" {
  description = "Network policy to use (azure, calico, or null)"
  type        = string
  default     = "azure"

  validation {
    condition     = var.network_policy == null || contains(["azure", "calico"], var.network_policy)
    error_message = "network_policy must be null, 'azure', or 'calico'"
  }
}

variable "dns_service_ip" {
  description = "DNS service IP address (must be within service_cidr range)"
  type        = string
  default     = "10.0.0.10"
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"
}

variable "pod_cidr" {
  description = "Pod CIDR (only used when network_plugin is 'kubenet')"
  type        = string
  default     = "10.244.0.0/16"
}

variable "outbound_type" {
  description = "Outbound traffic type (loadBalancer, userDefinedRouting, managedNATGateway)"
  type        = string
  default     = "loadBalancer"

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting", "managedNATGateway"], var.outbound_type)
    error_message = "outbound_type must be 'loadBalancer', 'userDefinedRouting', or 'managedNATGateway'"
  }
}

# -----------------------------------------------------------------------------
# Monitoring and Logging
# -----------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for Container Insights"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Azure Container Registry Integration
# -----------------------------------------------------------------------------

variable "acr_id" {
  description = "Azure Container Registry ID for AcrPull role assignment"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Security and Identity
# -----------------------------------------------------------------------------

variable "azure_policy_enabled" {
  description = "Enable Azure Policy add-on for AKS"
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Enable workload identity for pod-level authentication"
  type        = bool
  default     = true
}

variable "key_vault_secrets_provider_enabled" {
  description = "Enable Azure Key Vault secrets provider"
  type        = bool
  default     = true
}

variable "secret_rotation_enabled" {
  description = "Enable automatic secret rotation for Key Vault secrets"
  type        = bool
  default     = true
}

variable "secret_rotation_interval" {
  description = "Interval for secret rotation (e.g., 2m)"
  type        = string
  default     = "2m"
}

variable "azure_ad_rbac_enabled" {
  description = "Enable Azure AD integration for RBAC"
  type        = bool
  default     = false
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = false
}

variable "admin_group_object_ids" {
  description = "List of Azure AD group object IDs for cluster admin access"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Auto Scaler Profile
# -----------------------------------------------------------------------------

variable "auto_scaler_profile" {
  description = "Configuration for the cluster autoscaler"
  type = object({
    balance_similar_node_groups      = optional(bool, false)
    expander                         = optional(string, "random")
    max_graceful_termination_sec     = optional(number, 600)
    max_node_provisioning_time       = optional(string, "15m")
    max_unready_nodes                = optional(number, 3)
    max_unready_percentage           = optional(number, 45)
    new_pod_scale_up_delay           = optional(string, "10s")
    scale_down_delay_after_add       = optional(string, "10m")
    scale_down_delay_after_delete    = optional(string, "10s")
    scale_down_delay_after_failure   = optional(string, "3m")
    scan_interval                    = optional(string, "10s")
    scale_down_unneeded              = optional(string, "10m")
    scale_down_unready               = optional(string, "20m")
    scale_down_utilization_threshold = optional(number, 0.5)
    skip_nodes_with_local_storage    = optional(bool, true)
    skip_nodes_with_system_pods      = optional(bool, true)
  })
  default = {}
}

# -----------------------------------------------------------------------------
# Maintenance Window
# -----------------------------------------------------------------------------

variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    allowed = optional(list(object({
      day   = string
      hours = list(number)
    })))
  })
  default = null
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
