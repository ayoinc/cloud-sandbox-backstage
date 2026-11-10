variable "name" {
  description = "Project name used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds the resources of this module"
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}

variable "kubernetes_version" {
  description = "Kubernetes version: a minor version (1.37), for which AKS selects the latest patch, or a full version"
  type        = string
}

variable "node_vm_size" {
  description = "VM size of the system and user nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "node_count" {
  description = "Initial number of user nodes"
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum number of user nodes for the autoscaler"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of user nodes for the autoscaler"
  type        = number
  default     = 5
}

variable "enable_high_availability" {
  description = "Spread nodes over three availability zones and use the Standard tier with its uptime SLA"
  type        = bool
  default     = false
}

variable "enable_vnet_integration" {
  description = "Place the nodes in vnet_subnet_id instead of a network managed by AKS"
  type        = bool
  default     = false
}

variable "vnet_subnet_id" {
  description = "Subnet for the nodes and pods (used with enable_vnet_integration)"
  type        = string
  default     = null
}

variable "service_cidr" {
  description = "Address range of Kubernetes services; must not overlap the virtual network"
  type        = string
  default     = "172.16.0.0/16"
}

variable "enable_container_insights" {
  description = "Send container logs and metrics to log_analytics_workspace_id"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace for Container Insights (used with enable_container_insights)"
  type        = string
  default     = null
}

variable "acr_sku" {
  description = "Container Registry SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be one of: Basic, Standard, Premium."
  }
}

variable "georeplication_location" {
  description = "Region that holds a replica of the registry (Premium SKU only, null for none)"
  type        = string
  default     = null
}

variable "private_cluster_enabled" {
  description = "Expose the API server only inside the virtual network"
  type        = bool
  default     = false
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDR ranges allowed to reach the public API server (empty allows any address)"
  type        = list(string)
  default     = []
}

variable "enable_host_encryption" {
  description = "Encrypt temp disks and caches on the node hosts (needs the EncryptionAtHost subscription feature)"
  type        = bool
  default     = false
}
