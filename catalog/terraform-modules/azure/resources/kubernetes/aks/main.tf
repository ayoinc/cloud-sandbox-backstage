# =============================================================================
# AZURE KUBERNETES SERVICE (AKS) MODULE
# =============================================================================
# Creates AKS cluster with node pools, networking, and monitoring
# Follows Azure best practices for production Kubernetes
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = null
}

variable "dns_prefix" {
  description = "DNS prefix for the cluster"
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "SKU tier (Free, Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for private cluster"
  type        = string
  default     = null
}

# Default node pool configuration
variable "default_node_pool" {
  description = "Default node pool configuration"
  type = object({
    name                 = optional(string, "system")
    vm_size              = optional(string, "Standard_D2s_v3")
    node_count           = optional(number, 2)
    min_count            = optional(number, 1)
    max_count            = optional(number, 5)
    enable_auto_scaling  = optional(bool, true)
    max_pods             = optional(number, 30)
    os_disk_size_gb      = optional(number, 128)
    os_disk_type         = optional(string, "Managed")
    vnet_subnet_id       = optional(string, null)
    zones                = optional(list(string), ["1", "2", "3"])
    node_labels          = optional(map(string), {})
    node_taints          = optional(list(string), [])
    only_critical_addons = optional(bool, true)
  })
  default = {}
}

# Additional node pools
variable "additional_node_pools" {
  description = "Additional node pools"
  type = map(object({
    vm_size             = string
    node_count          = optional(number, 1)
    min_count           = optional(number, 1)
    max_count           = optional(number, 10)
    enable_auto_scaling = optional(bool, true)
    max_pods            = optional(number, 30)
    os_disk_size_gb     = optional(number, 128)
    os_disk_type        = optional(string, "Managed")
    os_type             = optional(string, "Linux")
    vnet_subnet_id      = optional(string, null)
    zones               = optional(list(string), ["1", "2", "3"])
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
    mode                = optional(string, "User")
    priority            = optional(string, "Regular")
    spot_max_price      = optional(number, null)
  }))
  default = {}
}

# Network configuration
variable "network_profile" {
  description = "Network profile configuration"
  type = object({
    network_plugin    = optional(string, "azure")
    network_policy    = optional(string, "azure")
    network_mode      = optional(string, "transparent")
    dns_service_ip    = optional(string, "10.2.0.10")
    service_cidr      = optional(string, "10.2.0.0/16")
    load_balancer_sku = optional(string, "standard")
    outbound_type     = optional(string, "loadBalancer")
  })
  default = {}
}

# Identity
variable "identity_type" {
  description = "Identity type (SystemAssigned, UserAssigned)"
  type        = string
  default     = "SystemAssigned"
}

variable "user_assigned_identity_id" {
  description = "User assigned identity ID"
  type        = string
  default     = null
}

# Azure AD integration
variable "azure_ad_managed" {
  description = "Enable Azure AD managed integration"
  type        = bool
  default     = true
}

variable "azure_ad_admin_group_ids" {
  description = "Azure AD group IDs for cluster admin"
  type        = list(string)
  default     = []
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes"
  type        = bool
  default     = true
}

# Monitoring
variable "enable_oms_agent" {
  description = "Enable OMS agent for monitoring"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

# Container Registry
variable "acr_id" {
  description = "Azure Container Registry ID for pull permissions"
  type        = string
  default     = null
}

# Maintenance
variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    allowed = list(object({
      day   = string
      hours = list(number)
    }))
  })
  default = null
}

variable "automatic_upgrade_channel" {
  description = "Automatic upgrade channel (none, patch, rapid, stable, node-image)"
  type        = string
  default     = "stable"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  cluster_name = "aks-${var.project}-${var.environment}-${var.location}"
  dns_prefix   = var.dns_prefix != null ? var.dns_prefix : "aks-${var.project}-${var.environment}"

  # Environment-specific defaults
  env_config = {
    dev = {
      sku_tier   = "Free"
      vm_size    = "Standard_B2s"
      node_count = 1
      max_count  = 3
    }
    staging = {
      sku_tier   = "Standard"
      vm_size    = "Standard_D2s_v3"
      node_count = 2
      max_count  = 5
    }
    prod = {
      sku_tier   = "Standard"
      vm_size    = "Standard_D4s_v3"
      node_count = 3
      max_count  = 10
    }
  }

  config = lookup(local.env_config, var.environment, local.env_config["dev"])
}

# -----------------------------------------------------------------------------
# AKS Cluster
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster" "main" {
  name                      = local.cluster_name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = local.dns_prefix
  kubernetes_version        = var.kubernetes_version
  sku_tier                  = var.sku_tier
  private_cluster_enabled   = var.private_cluster_enabled
  private_dns_zone_id       = var.private_cluster_enabled ? var.private_dns_zone_id : null
  automatic_channel_upgrade = var.automatic_upgrade_channel

  default_node_pool {
    name                         = var.default_node_pool.name
    vm_size                      = var.default_node_pool.vm_size
    node_count                   = var.default_node_pool.enable_auto_scaling ? null : var.default_node_pool.node_count
    min_count                    = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.min_count : null
    max_count                    = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.max_count : null
    enable_auto_scaling          = var.default_node_pool.enable_auto_scaling
    max_pods                     = var.default_node_pool.max_pods
    os_disk_size_gb              = var.default_node_pool.os_disk_size_gb
    os_disk_type                 = var.default_node_pool.os_disk_type
    vnet_subnet_id               = var.default_node_pool.vnet_subnet_id
    zones                        = var.default_node_pool.zones
    node_labels                  = var.default_node_pool.node_labels
    only_critical_addons_enabled = var.default_node_pool.only_critical_addons
    temporary_name_for_rotation  = "temp${var.default_node_pool.name}"
  }

  identity {
    type         = var.identity_type
    identity_ids = var.identity_type == "UserAssigned" ? [var.user_assigned_identity_id] : null
  }

  network_profile {
    network_plugin    = var.network_profile.network_plugin
    network_policy    = var.network_profile.network_policy
    dns_service_ip    = var.network_profile.dns_service_ip
    service_cidr      = var.network_profile.service_cidr
    load_balancer_sku = var.network_profile.load_balancer_sku
    outbound_type     = var.network_profile.outbound_type
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.azure_ad_managed ? [1] : []
    content {
      managed                = true
      azure_rbac_enabled     = var.azure_rbac_enabled
      admin_group_object_ids = var.azure_ad_admin_group_ids
    }
  }

  dynamic "oms_agent" {
    for_each = var.enable_oms_agent && var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      dynamic "allowed" {
        for_each = maintenance_window.value.allowed
        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Additional Node Pools
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  node_count            = each.value.enable_auto_scaling ? null : each.value.node_count
  min_count             = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_count : null
  enable_auto_scaling   = each.value.enable_auto_scaling
  max_pods              = each.value.max_pods
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  os_type               = each.value.os_type
  vnet_subnet_id        = each.value.vnet_subnet_id
  zones                 = each.value.zones
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  mode                  = each.value.mode
  priority              = each.value.priority
  spot_max_price        = each.value.priority == "Spot" ? each.value.spot_max_price : null

  tags = var.tags
}

# -----------------------------------------------------------------------------
# ACR Pull Permission
# -----------------------------------------------------------------------------

resource "azurerm_role_assignment" "acr_pull" {
  count = var.acr_id != null ? 1 : 0

  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "cluster_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_private_fqdn" {
  description = "AKS cluster private FQDN"
  value       = azurerm_kubernetes_cluster.main.private_fqdn
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_config_host" {
  description = "Kubernetes API server host"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

output "kubelet_identity" {
  description = "Kubelet managed identity"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0]
}

output "identity_principal_id" {
  description = "Cluster identity principal ID"
  value       = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

output "node_resource_group" {
  description = "Auto-generated resource group for nodes"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}
