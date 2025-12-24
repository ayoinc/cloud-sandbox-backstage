# =============================================================================
# Azure AKS - Root Variables
# =============================================================================
# These variables are passed to the child module.
# Values are provided via environment-specific .tfvars files.
# NO Jinja2 defaults here - all values come from tfvars.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
}

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

# -----------------------------------------------------------------------------
# System Node Pool Configuration
# -----------------------------------------------------------------------------

variable "system_node_vm_size" {
  description = "VM size for system node pool"
  type        = string
}

variable "system_node_count" {
  description = "Initial node count for system pool"
  type        = number
}

variable "system_min_count" {
  description = "Minimum node count for system pool"
  type        = number
}

variable "system_max_count" {
  description = "Maximum node count for system pool"
  type        = number
}

# -----------------------------------------------------------------------------
# User Node Pool Configuration
# -----------------------------------------------------------------------------

variable "create_user_node_pool" {
  description = "Create a separate user node pool"
  type        = bool
  default     = true
}

variable "user_node_vm_size" {
  description = "VM size for user node pool"
  type        = string
}

variable "user_node_count" {
  description = "Initial node count for user pool"
  type        = number
}

variable "user_min_count" {
  description = "Minimum node count for user pool"
  type        = number
}

variable "user_max_count" {
  description = "Maximum node count for user pool"
  type        = number
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
  description = "Create a spot node pool"
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
  description = "Maximum price for spot instances"
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
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

variable "max_surge" {
  description = "Max surge for upgrades"
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
  description = "Network plugin (azure or kubenet)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy (calico or azure)"
  type        = string
  default     = "calico"
}

variable "outbound_type" {
  description = "Outbound routing type"
  type        = string
  default     = "loadBalancer"
}

variable "vnet_subnet_id" {
  description = "Subnet ID for AKS deployment"
  type        = string
  default     = ""
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP"
  type        = string
  default     = "10.0.0.10"
}

# -----------------------------------------------------------------------------
# Container Registry
# -----------------------------------------------------------------------------

variable "create_acr" {
  description = "Create Azure Container Registry"
  type        = bool
  default     = true
}

variable "acr_sku" {
  description = "ACR SKU"
  type        = string
  default     = "Standard"
}

variable "acr_georeplication_locations" {
  description = "Geo-replication locations for ACR"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Log Analytics retention in days"
  type        = number
  default     = 30
}

variable "enable_defender" {
  description = "Enable Microsoft Defender"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Security
# -----------------------------------------------------------------------------

variable "enable_azure_rbac" {
  description = "Enable Azure RBAC"
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Azure AD admin group IDs"
  type        = list(string)
  default     = []
}

variable "enable_workload_identity" {
  description = "Enable workload identity"
  type        = bool
  default     = true
}

variable "enable_secret_rotation" {
  description = "Enable secret rotation"
  type        = bool
  default     = false
}

variable "secret_rotation_interval" {
  description = "Secret rotation interval"
  type        = string
  default     = "2m"
}

# -----------------------------------------------------------------------------
# Upgrades
# -----------------------------------------------------------------------------

variable "automatic_channel_upgrade" {
  description = "Automatic upgrade channel"
  type        = string
  default     = "patch"
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
# Autoscaler
# -----------------------------------------------------------------------------

variable "scale_down_delay_after_add" {
  description = "Delay after adding a node"
  type        = string
  default     = "10m"
}

variable "scale_down_unneeded" {
  description = "Time node must be unneeded"
  type        = string
  default     = "10m"
}

variable "scale_down_utilization_threshold" {
  description = "Utilization threshold for scale down"
  type        = string
  default     = "0.5"
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
