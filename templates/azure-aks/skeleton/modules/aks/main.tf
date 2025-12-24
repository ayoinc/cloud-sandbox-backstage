# =============================================================================
# Azure AKS Module
# =============================================================================
# This module creates a complete Azure Kubernetes Service cluster including:
# - Resource Group
# - Log Analytics Workspace
# - Container Registry
# - User Assigned Identity
# - AKS Cluster with system and user node pools
# - Diagnostic Settings
# =============================================================================

locals {
  # Naming convention: {resource-type}-{name}-{environment}
  resource_group_name = "rg-${var.name}-${var.environment}"
  aks_name            = "aks-${var.name}-${var.environment}"
  acr_name            = replace("acr${var.name}${var.environment}", "-", "")
  log_analytics_name  = "law-${var.name}-${var.environment}"
  identity_name       = "id-${var.name}-${var.environment}"

  # Common tags applied to all resources
  common_tags = merge(var.tags, {
    Project     = var.name
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # Environment-based settings
  is_production = var.environment == "prod" || var.environment == "production"
}

# =============================================================================
# Resource Group
# =============================================================================
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# =============================================================================
# Log Analytics Workspace
# =============================================================================
resource "azurerm_log_analytics_workspace" "main" {
  name                = local.log_analytics_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = local.common_tags
}

# =============================================================================
# Container Registry
# =============================================================================
resource "azurerm_container_registry" "main" {
  count = var.create_acr ? 1 : 0

  name                = local.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = false

  # Geo-replication for Premium SKU in production
  dynamic "georeplications" {
    for_each = var.acr_sku == "Premium" && length(var.acr_georeplication_locations) > 0 ? var.acr_georeplication_locations : []
    content {
      location                = georeplications.value
      zone_redundancy_enabled = true
    }
  }

  tags = local.common_tags
}

# =============================================================================
# User Assigned Identity
# =============================================================================
resource "azurerm_user_assigned_identity" "aks" {
  name                = local.identity_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# =============================================================================
# Role Assignments
# =============================================================================

# ACR Pull role for AKS
resource "azurerm_role_assignment" "aks_acr" {
  count = var.create_acr ? 1 : 0

  scope                = azurerm_container_registry.main[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Network Contributor for subnet (if using existing VNet)
resource "azurerm_role_assignment" "aks_network" {
  count = var.vnet_subnet_id != "" ? 1 : 0

  scope                = var.vnet_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# =============================================================================
# AKS Cluster
# =============================================================================
resource "azurerm_kubernetes_cluster" "main" {
  name                = local.aks_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.name}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  # SKU Tier
  sku_tier = local.is_production ? "Standard" : "Free"

  # Automatic channel upgrade
  automatic_channel_upgrade = var.automatic_channel_upgrade

  # System Node Pool
  default_node_pool {
    name                         = "system"
    node_count                   = var.system_node_count
    vm_size                      = var.system_node_vm_size
    enable_auto_scaling          = var.enable_auto_scaling
    min_count                    = var.enable_auto_scaling ? var.system_min_count : null
    max_count                    = var.enable_auto_scaling ? var.system_max_count : null
    os_disk_size_gb              = var.os_disk_size_gb
    os_disk_type                 = "Managed"
    type                         = "VirtualMachineScaleSets"
    vnet_subnet_id               = var.vnet_subnet_id != "" ? var.vnet_subnet_id : null
    only_critical_addons_enabled = true

    zones = var.availability_zones

    upgrade_settings {
      max_surge = var.max_surge
    }

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }
  }

  # Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Network Profile
  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    load_balancer_sku = "standard"
    outbound_type     = var.outbound_type

    # Only set these if using Azure CNI
    service_cidr   = var.network_plugin == "azure" ? var.service_cidr : null
    dns_service_ip = var.network_plugin == "azure" ? var.dns_service_ip : null
  }

  # Azure Monitor
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  # Microsoft Defender
  dynamic "microsoft_defender" {
    for_each = var.enable_defender ? [1] : []
    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
    }
  }

  # Azure AD Integration
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = var.enable_azure_rbac
    admin_group_object_ids = var.admin_group_object_ids
  }

  # Workload Identity
  workload_identity_enabled = var.enable_workload_identity
  oidc_issuer_enabled       = var.enable_workload_identity

  # Key Vault Secrets Provider
  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_secret_rotation ? [1] : []
    content {
      secret_rotation_enabled  = true
      secret_rotation_interval = var.secret_rotation_interval
    }
  }

  # Auto Scaler Profile
  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                         = "random"
    max_graceful_termination_sec     = 600
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "10s"
    scale_down_delay_after_add       = var.scale_down_delay_after_add
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scan_interval                    = "10s"
    scale_down_unneeded              = var.scale_down_unneeded
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = var.scale_down_utilization_threshold
    empty_bulk_delete_max            = 10
    skip_nodes_with_local_storage    = true
    skip_nodes_with_system_pods      = true
  }

  # Maintenance Window
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      allowed {
        day   = maintenance_window.value.day
        hours = maintenance_window.value.hours
      }
    }
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version,
    ]
  }
}

# =============================================================================
# User Node Pool
# =============================================================================
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count = var.create_user_node_pool ? 1 : 0

  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_node_vm_size
  node_count            = var.user_node_count
  enable_auto_scaling   = var.enable_auto_scaling
  min_count             = var.enable_auto_scaling ? var.user_min_count : null
  max_count             = var.enable_auto_scaling ? var.user_max_count : null
  os_disk_size_gb       = var.os_disk_size_gb
  os_disk_type          = "Managed"
  vnet_subnet_id        = var.vnet_subnet_id != "" ? var.vnet_subnet_id : null

  zones = var.availability_zones

  node_labels = {
    "nodepool-type" = "user"
    "workload"      = "user"
    "environment"   = var.environment
  }

  node_taints = var.user_node_taints

  upgrade_settings {
    max_surge = var.max_surge
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}

# =============================================================================
# Spot Node Pool (Optional - for cost savings)
# =============================================================================
resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  count = var.create_spot_node_pool ? 1 : 0

  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.spot_node_vm_size
  node_count            = var.spot_node_count
  enable_auto_scaling   = true
  min_count             = 0
  max_count             = var.spot_max_count
  os_disk_size_gb       = var.os_disk_size_gb
  os_disk_type          = "Managed"
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = var.spot_max_price
  vnet_subnet_id        = var.vnet_subnet_id != "" ? var.vnet_subnet_id : null

  zones = var.availability_zones

  node_labels = {
    "nodepool-type"                         = "spot"
    "kubernetes.azure.com/scalesetpriority" = "spot"
    "environment"                           = var.environment
  }

  node_taints = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]

  upgrade_settings {
    max_surge = var.max_surge
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}

# =============================================================================
# Diagnostic Settings
# =============================================================================
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "aks-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  enabled_log {
    category = "guard"
  }

  metric {
    category = "AllMetrics"
  }
}
