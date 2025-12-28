# =============================================================================
# CONTAINERS MODULE FOR AZURE FULL INFRASTRUCTURE
# =============================================================================
# Creates AKS and ACR
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

variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "enable_aks" {
  type    = bool
  default = true
}

variable "enable_acr" {
  type    = bool
  default = true
}

variable "subnet_id" {
  type    = string
  default = null
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "node_pools" {
  type = map(object({
    vm_size             = string
    node_count          = optional(number, 2)
    min_count           = optional(number, 1)
    max_count           = optional(number, 5)
    enable_auto_scaling = optional(bool, true)
  }))
  default = {
    default = {
      vm_size    = "Standard_D2s_v3"
      node_count = 2
    }
  }
}

variable "acr_sku" {
  type    = string
  default = "Standard"
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

# -----------------------------------------------------------------------------
# Container Registry
# -----------------------------------------------------------------------------

resource "azurerm_container_registry" "main" {
  count = var.enable_acr ? 1 : 0

  name                = replace("${var.name_prefix}acr", "-", "")
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = false
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# AKS Cluster
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster" "main" {
  count = var.enable_aks ? 1 : 0

  name                = "${var.name_prefix}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = replace(var.name_prefix, "-", "")
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "default"
    vm_size             = var.node_pools["default"].vm_size
    node_count          = var.node_pools["default"].enable_auto_scaling ? null : var.node_pools["default"].node_count
    min_count           = var.node_pools["default"].enable_auto_scaling ? var.node_pools["default"].min_count : null
    max_count           = var.node_pools["default"].enable_auto_scaling ? var.node_pools["default"].max_count : null
    enable_auto_scaling = var.node_pools["default"].enable_auto_scaling
    vnet_subnet_id      = var.subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  tags = var.tags
}

# ACR Pull Permission for AKS
resource "azurerm_role_assignment" "acr_pull" {
  count = var.enable_aks && var.enable_acr ? 1 : 0

  principal_id                     = azurerm_kubernetes_cluster.main[0].kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main[0].id
  skip_service_principal_aad_check = true
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "aks_cluster_id" {
  value = var.enable_aks ? azurerm_kubernetes_cluster.main[0].id : null
}

output "aks_cluster_name" {
  value = var.enable_aks ? azurerm_kubernetes_cluster.main[0].name : null
}

output "kube_config" {
  value     = var.enable_aks ? azurerm_kubernetes_cluster.main[0].kube_config_raw : null
  sensitive = true
}

output "acr_id" {
  value = var.enable_acr ? azurerm_container_registry.main[0].id : null
}

output "acr_login_server" {
  value = var.enable_acr ? azurerm_container_registry.main[0].login_server : null
}
