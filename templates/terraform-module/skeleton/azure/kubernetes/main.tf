# -----------------------------------------------------------------------------
# Azure Kubernetes Service (AKS) Module - Main Resources
# -----------------------------------------------------------------------------

# Data source for current subscription
data "azurerm_subscription" "current" {}

# User Assigned Managed Identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.project_name}-${var.environment}-aks-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# Role Assignment - Network Contributor (for AKS to manage subnet)
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Role Assignment - AcrPull (for AKS to pull images from ACR)
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = var.acr_id != null ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# Azure Kubernetes Service Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_name}-${var.environment}-aks"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = "${var.project_name}-${var.environment}"

  kubernetes_version        = var.kubernetes_version
  automatic_upgrade_channel = var.automatic_upgrade_channel
  sku_tier                  = var.sku_tier

  # Enable private cluster if specified
  private_cluster_enabled = var.private_cluster_enabled

  # Azure Policy Integration
  azure_policy_enabled = var.azure_policy_enabled

  # Workload Identity for pod-level authentication
  workload_identity_enabled = var.workload_identity_enabled
  oidc_issuer_enabled       = var.workload_identity_enabled

  # Default Node Pool
  default_node_pool {
    name                         = var.default_node_pool.name
    vm_size                      = var.default_node_pool.vm_size
    vnet_subnet_id               = var.subnet_id
    zones                        = var.default_node_pool.zones
    node_count                   = var.default_node_pool.enable_auto_scaling ? null : var.default_node_pool.node_count
    min_count                    = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.min_count : null
    max_count                    = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.max_count : null
    auto_scaling_enabled         = var.default_node_pool.enable_auto_scaling
    max_pods                     = var.default_node_pool.max_pods
    os_disk_size_gb              = var.default_node_pool.os_disk_size_gb
    os_disk_type                 = var.default_node_pool.os_disk_type
    temporary_name_for_rotation  = "tempdefault"
    only_critical_addons_enabled = var.default_node_pool.only_critical_addons_enabled

    upgrade_settings {
      max_surge                     = var.default_node_pool.max_surge
      drain_timeout_in_minutes      = 30
      node_soak_duration_in_minutes = 0
    }

    tags = var.tags
  }

  # User Assigned Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Network Profile
  network_profile {
    network_plugin      = var.network_plugin
    network_plugin_mode = var.network_plugin == "azure" ? var.network_plugin_mode : null
    network_policy      = var.network_policy
    dns_service_ip      = var.dns_service_ip
    service_cidr        = var.service_cidr
    pod_cidr            = var.network_plugin == "kubenet" ? var.pod_cidr : null
    load_balancer_sku   = "standard"
    outbound_type       = var.outbound_type
  }

  # OMS Agent for Container Insights
  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id      = var.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = true
    }
  }

  # Key Vault Secrets Provider
  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider_enabled ? [1] : []
    content {
      secret_rotation_enabled  = var.secret_rotation_enabled
      secret_rotation_interval = var.secret_rotation_interval
    }
  }

  # Azure Active Directory Integration
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.azure_ad_rbac_enabled ? [1] : []
    content {
      azure_rbac_enabled     = var.azure_rbac_enabled
      admin_group_object_ids = var.admin_group_object_ids
    }
  }

  # Auto Scaler Profile
  auto_scaler_profile {
    balance_similar_node_groups      = var.auto_scaler_profile.balance_similar_node_groups
    expander                         = var.auto_scaler_profile.expander
    max_graceful_termination_sec     = var.auto_scaler_profile.max_graceful_termination_sec
    max_node_provisioning_time       = var.auto_scaler_profile.max_node_provisioning_time
    max_unready_nodes                = var.auto_scaler_profile.max_unready_nodes
    max_unready_percentage           = var.auto_scaler_profile.max_unready_percentage
    new_pod_scale_up_delay           = var.auto_scaler_profile.new_pod_scale_up_delay
    scale_down_delay_after_add       = var.auto_scaler_profile.scale_down_delay_after_add
    scale_down_delay_after_delete    = var.auto_scaler_profile.scale_down_delay_after_delete
    scale_down_delay_after_failure   = var.auto_scaler_profile.scale_down_delay_after_failure
    scan_interval                    = var.auto_scaler_profile.scan_interval
    scale_down_unneeded              = var.auto_scaler_profile.scale_down_unneeded
    scale_down_unready               = var.auto_scaler_profile.scale_down_unready
    scale_down_utilization_threshold = var.auto_scaler_profile.scale_down_utilization_threshold
    skip_nodes_with_local_storage    = var.auto_scaler_profile.skip_nodes_with_local_storage
    skip_nodes_with_system_pods      = var.auto_scaler_profile.skip_nodes_with_system_pods
  }

  # Maintenance Window
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      dynamic "allowed" {
        for_each = maintenance_window.value.allowed != null ? maintenance_window.value.allowed : []
        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-aks"
  })

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version,
    ]
  }

  depends_on = [
    azurerm_role_assignment.aks_network_contributor
  ]
}

# Additional Node Pools
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = { for np in var.additional_node_pools : np.name => np }

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = var.subnet_id
  zones                 = each.value.zones

  node_count           = each.value.enable_auto_scaling ? null : each.value.node_count
  min_count            = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count            = each.value.enable_auto_scaling ? each.value.max_count : null
  auto_scaling_enabled = each.value.enable_auto_scaling
  max_pods             = each.value.max_pods
  os_disk_size_gb      = each.value.os_disk_size_gb
  os_disk_type         = each.value.os_disk_type
  os_type              = each.value.os_type
  priority             = each.value.priority
  eviction_policy      = each.value.priority == "Spot" ? each.value.eviction_policy : null
  spot_max_price       = each.value.priority == "Spot" ? each.value.spot_max_price : null
  mode                 = each.value.mode

  node_labels = each.value.node_labels
  node_taints = each.value.node_taints

  upgrade_settings {
    max_surge                     = each.value.max_surge
    drain_timeout_in_minutes      = 30
    node_soak_duration_in_minutes = 0
  }

  tags = merge(var.tags, {
    NodePool = each.value.name
  })

  lifecycle {
    ignore_changes = [node_count]
  }
}
