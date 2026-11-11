# -----------------------------------------------------------------------------
# Azure Kubernetes Service (AKS) Module - Variables
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

variable "subnet_id" {
  description = "Subnet ID for AKS nodes. The cluster identity is granted Network Contributor on it"
  type        = string

  validation {
    condition     = var.subnet_id != null
    error_message = "subnet_id is required: enable the network module or pass the ID of an existing subnet."
  }
}

variable "node_resource_group_name" {
  description = "Name of the resource group AKS creates for node resources. Null uses <project>-<environment>-aks-nodes-rg"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Kubernetes Configuration
# -----------------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster (for example 1.34). Null uses the current AKS default version"
  type        = string
  default     = null
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

variable "node_os_upgrade_channel" {
  description = "Node OS upgrade channel (Unmanaged, SecurityPatch, NodeImage, None)"
  type        = string
  default     = "NodeImage"

  validation {
    condition     = contains(["Unmanaged", "SecurityPatch", "NodeImage", "None"], var.node_os_upgrade_channel)
    error_message = "node_os_upgrade_channel must be one of: Unmanaged, SecurityPatch, NodeImage, None"
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
  default     = true
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDR ranges allowed to reach the API server of a public cluster. Required when private_cluster_enabled is false"
  type        = list(string)
  nullable    = false
  default     = []

  validation {
    condition     = alltrue([for cidr in var.api_server_authorized_ip_ranges : can(cidrhost(cidr, 0)) && !endswith(cidr, "/0")])
    error_message = "Each authorized range must be a valid CIDR block and must not be a /0 range."
  }
}

# -----------------------------------------------------------------------------
# Default Node Pool Configuration
# -----------------------------------------------------------------------------

variable "default_node_pool" {
  description = "Configuration for the default (system) node pool. Empty zones deploys regionally, which works in every region"
  type = object({
    name                         = optional(string, "system")
    vm_size                      = optional(string, "Standard_D2s_v5")
    node_count                   = optional(number, 3)
    min_count                    = optional(number, 1)
    max_count                    = optional(number, 5)
    enable_auto_scaling          = optional(bool, true)
    max_pods                     = optional(number, 30)
    os_disk_size_gb              = optional(number, 128)
    os_disk_type                 = optional(string, "Managed")
    os_sku                       = optional(string, "AzureLinux")
    zones                        = optional(list(string), [])
    only_critical_addons_enabled = optional(bool, false)
    max_surge                    = optional(string, "33%")
  })
  nullable = false
  default  = {}

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,11}$", var.default_node_pool.name))
    error_message = "The default node pool name must be 1-12 lowercase letters and numbers and start with a letter."
  }

  validation {
    condition     = contains(["AzureLinux", "AzureLinux3", "Ubuntu", "Ubuntu2204", "Ubuntu2404"], var.default_node_pool.os_sku)
    error_message = "default_node_pool.os_sku must be AzureLinux, AzureLinux3, Ubuntu, Ubuntu2204 or Ubuntu2404."
  }
}

# -----------------------------------------------------------------------------
# Additional Node Pools Configuration
# -----------------------------------------------------------------------------

variable "additional_node_pools" {
  description = "List of additional node pools to create"
  type = list(object({
    name                = string
    vm_size             = optional(string, "Standard_D2s_v5")
    node_count          = optional(number, 1)
    min_count           = optional(number, 0)
    max_count           = optional(number, 5)
    enable_auto_scaling = optional(bool, true)
    max_pods            = optional(number, 30)
    os_disk_size_gb     = optional(number, 128)
    os_disk_type        = optional(string, "Managed")
    os_type             = optional(string, "Linux")
    zones               = optional(list(string), [])
    priority            = optional(string, "Regular")
    eviction_policy     = optional(string, "Delete")
    spot_max_price      = optional(number, -1)
    mode                = optional(string, "User")
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
    max_surge           = optional(string, "33%")
  }))
  nullable = false
  default  = []

  validation {
    condition = alltrue([
      for pool in var.additional_node_pools : can(regex(pool.os_type == "Windows" ? "^[a-z][a-z0-9]{0,5}$" : "^[a-z][a-z0-9]{0,11}$", pool.name))
    ])
    error_message = "Node pool names must be lowercase letters and numbers starting with a letter: up to 12 characters for Linux, 6 for Windows."
  }

  validation {
    condition     = length(distinct(var.additional_node_pools[*].name)) == length(var.additional_node_pools)
    error_message = "Node pool names must be unique."
  }

  validation {
    condition     = alltrue([for pool in var.additional_node_pools : contains(["Regular", "Spot"], pool.priority) && contains(["User", "System"], pool.mode)])
    error_message = "Node pool priority must be Regular or Spot, and mode must be User or System."
  }
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "network_plugin_mode" {
  description = "Azure CNI mode: overlay gives pods addresses from pod_cidr; null gives pods addresses from the node subnet"
  type        = string
  default     = "overlay"

  validation {
    condition     = var.network_plugin_mode == null || var.network_plugin_mode == "overlay"
    error_message = "network_plugin_mode must be null or 'overlay'"
  }
}

variable "network_policy" {
  description = "Network policy engine: cilium (overlay mode, also selects the Cilium data plane), calico, azure (node-subnet mode only) or null for none"
  type        = string
  default     = "cilium"

  validation {
    condition     = var.network_policy == null || contains(["azure", "calico", "cilium"], coalesce(var.network_policy, "cilium"))
    error_message = "network_policy must be null, 'azure', 'calico', or 'cilium'"
  }
}

variable "dns_service_ip" {
  description = "DNS service IP address (must be within service_cidr range)"
  type        = string
  default     = "172.16.0.10"
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes services (must not overlap the virtual network)"
  type        = string
  default     = "172.16.0.0/16"

  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "service_cidr must be a valid CIDR block."
  }
}

variable "pod_cidr" {
  description = "Pod CIDR used in overlay mode (must not overlap the virtual network or service_cidr)"
  type        = string
  default     = "10.244.0.0/16"

  validation {
    condition     = can(cidrhost(var.pod_cidr, 0))
    error_message = "pod_cidr must be a valid CIDR block."
  }
}

variable "outbound_type" {
  description = "Outbound traffic type (loadBalancer, userDefinedRouting, managedNATGateway, userAssignedNATGateway). Use userAssignedNATGateway when the node subnet already has a NAT Gateway"
  type        = string
  default     = "loadBalancer"

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting", "managedNATGateway", "userAssignedNATGateway"], var.outbound_type)
    error_message = "outbound_type must be 'loadBalancer', 'userDefinedRouting', 'managedNATGateway', or 'userAssignedNATGateway'"
  }
}

# -----------------------------------------------------------------------------
# Monitoring and Logging
# -----------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for Container Insights. Null disables the add-on. The value must be known at plan time"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Azure Container Registry Integration
# -----------------------------------------------------------------------------

variable "acr_id" {
  description = "Azure Container Registry ID for AcrPull role assignment. Null creates no assignment. The value must be known at plan time"
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

variable "local_account_disabled" {
  description = "Disable local (certificate) accounts when azure_ad_rbac_enabled is true, so that every sign-in goes through Microsoft Entra ID"
  type        = bool
  default     = true
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = false
}

variable "admin_group_object_ids" {
  description = "List of Azure AD group object IDs for cluster admin access"
  type        = list(string)
  nullable    = false
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
  nullable = false
  default  = {}
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
    })), [])
  })
  default = null
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  nullable    = false
  default     = {}
}
