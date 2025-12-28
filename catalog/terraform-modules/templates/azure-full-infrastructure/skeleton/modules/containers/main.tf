# =============================================================================
# CONTAINERS MODULE (AKS + ACR)
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

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "project" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string) }
variable "kubernetes_version" { type = string; default = "1.28" }
variable "node_count" { type = number; default = 3 }
variable "node_vm_size" { type = string; default = "Standard_D4s_v3" }
variable "enable_auto_scaling" { type = bool; default = false }
variable "min_node_count" { type = number; default = 1 }
variable "max_node_count" { type = number; default = 10 }
variable "vnet_subnet_id" { type = string; default = null }
variable "log_analytics_workspace_id" { type = string; default = null }

locals {
  aks_name = "aks-${var.project}-${var.environment}-${var.location}"
  acr_name = lower(replace("acr${var.project}${var.environment}", "-", ""))
}

resource "azurerm_container_registry" "main" {
  name                = substr(local.acr_name, 0, 50)
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.environment == "prod" ? "Premium" : "Standard"
  admin_enabled       = false
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = local.aks_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "default"
    node_count          = var.enable_auto_scaling ? null : var.node_count
    vm_size             = var.node_vm_size
    vnet_subnet_id      = var.vnet_subnet_id
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.min_node_count : null
    max_count           = var.enable_auto_scaling ? var.max_node_count : null
  }

  identity {
    type = "SystemAssigned"
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}

output "aks_cluster_id" { value = azurerm_kubernetes_cluster.main.id }
output "aks_cluster_name" { value = azurerm_kubernetes_cluster.main.name }
output "aks_cluster_fqdn" { value = azurerm_kubernetes_cluster.main.fqdn }
output "acr_id" { value = azurerm_container_registry.main.id }
output "acr_login_server" { value = azurerm_container_registry.main.login_server }
output "kube_config" { value = azurerm_kubernetes_cluster.main.kube_config_raw; sensitive = true }
