# -----------------------------------------------------------------------------
# Azure Kubernetes Service (AKS) Module - Main Resources
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  node_resource_group = var.node_resource_group_name != null ? var.node_resource_group_name : "${local.name_prefix}-aks-nodes-rg"

  overlay_enabled = var.network_plugin_mode == "overlay"

  node_pools = { for pool in var.additional_node_pools : pool.name => pool }
}

# -----------------------------------------------------------------------------
# Cluster Identity
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "aks" {
  name                = "${local.name_prefix}-aks-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# The cluster joins nodes and internal load balancers to the node subnet.
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                            = var.subnet_id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.aks.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

# -----------------------------------------------------------------------------
# Kubelet Identity
# -----------------------------------------------------------------------------

# Nodes authenticate with this identity, so registry access is granted before
# the first node starts.
resource "azurerm_user_assigned_identity" "kubelet" {
  name                = "${local.name_prefix}-aks-kubelet-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# The cluster identity assigns the kubelet identity to the node scale sets.
resource "azurerm_role_assignment" "aks_kubelet_identity_operator" {
  scope                            = azurerm_user_assigned_identity.kubelet.id
  role_definition_name             = "Managed Identity Operator"
  principal_id                     = azurerm_user_assigned_identity.aks.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  count = var.acr_id != null ? 1 : 0

  scope                            = var.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_user_assigned_identity.kubelet.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

# -----------------------------------------------------------------------------
# AKS Cluster
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${local.name_prefix}-aks"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = local.name_prefix
  node_resource_group = local.node_resource_group

  kubernetes_version        = var.kubernetes_version
  automatic_upgrade_channel = var.automatic_upgrade_channel == "none" ? null : var.automatic_upgrade_channel
  node_os_upgrade_channel   = var.node_os_upgrade_channel
  sku_tier                  = var.sku_tier

  private_cluster_enabled = var.private_cluster_enabled

  # A public API server only answers the listed address ranges.
  dynamic "api_server_access_profile" {
    for_each = var.private_cluster_enabled ? [] : [1]

    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  role_based_access_control_enabled = true
  local_account_disabled            = var.azure_ad_rbac_enabled && var.local_account_disabled

  azure_policy_enabled = var.azure_policy_enabled

  workload_identity_enabled = var.workload_identity_enabled
  oidc_issuer_enabled       = var.workload_identity_enabled

  default_node_pool {
    name                         = var.default_node_pool.name
    vm_size                      = var.default_node_pool.vm_size
    vnet_subnet_id               = var.subnet_id
    zones                        = length(var.default_node_pool.zones) > 0 ? var.default_node_pool.zones : null
    node_count                   = var.default_node_pool.enable_auto_scaling ? null : var.default_node_pool.node_count
    min_count                    = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.min_count : null
    max_count                    = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.max_count : null
    auto_scaling_enabled         = var.default_node_pool.enable_auto_scaling
    max_pods                     = var.default_node_pool.max_pods
    os_disk_size_gb              = var.default_node_pool.os_disk_size_gb
    os_disk_type                 = var.default_node_pool.os_disk_type
    os_sku                       = var.default_node_pool.os_sku
    temporary_name_for_rotation  = "tempdefault"
    only_critical_addons_enabled = var.default_node_pool.only_critical_addons_enabled

    upgrade_settings {
      max_surge                     = var.default_node_pool.max_surge
      drain_timeout_in_minutes      = 30
      node_soak_duration_in_minutes = 0
    }

    tags = var.tags
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = var.network_plugin_mode
    network_policy      = var.network_policy
    network_data_plane  = var.network_policy == "cilium" ? "cilium" : "azure"
    dns_service_ip      = var.dns_service_ip
    service_cidr        = var.service_cidr
    pod_cidr            = local.overlay_enabled ? var.pod_cidr : null
    load_balancer_sku   = "standard"
    outbound_type       = var.outbound_type
  }

  # Container Insights
  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []

    content {
      log_analytics_workspace_id      = var.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = true
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider_enabled ? [1] : []

    content {
      secret_rotation_enabled  = var.secret_rotation_enabled
      secret_rotation_interval = var.secret_rotation_interval
    }
  }

  # Microsoft Entra ID sign-in for the Kubernetes API
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.azure_ad_rbac_enabled ? [1] : []

    content {
      azure_rbac_enabled     = var.azure_rbac_enabled
      admin_group_object_ids = var.admin_group_object_ids
    }
  }

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

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-aks"
  })

  lifecycle {
    # The autoscaler owns the node count and the upgrade channel the version.
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version,
    ]

    precondition {
      condition     = var.private_cluster_enabled || length(var.api_server_authorized_ip_ranges) > 0
      error_message = "A public API server needs api_server_authorized_ip_ranges: list the address ranges that may reach it, or keep private_cluster_enabled = true."
    }
    precondition {
      condition     = var.network_policy != "cilium" || local.overlay_enabled
      error_message = "network_policy \"cilium\" requires network_plugin_mode = \"overlay\"."
    }
    precondition {
      condition     = var.network_policy != "azure" || !local.overlay_enabled
      error_message = "network_policy \"azure\" is not available with network_plugin_mode = \"overlay\": use cilium or calico."
    }
    precondition {
      condition     = !var.default_node_pool.enable_auto_scaling || (var.default_node_pool.min_count >= 1 && var.default_node_pool.min_count <= var.default_node_pool.max_count)
      error_message = "The default node pool needs 1 <= min_count <= max_count."
    }
    precondition {
      condition     = !var.azure_rbac_enabled || var.azure_ad_rbac_enabled
      error_message = "azure_rbac_enabled requires azure_ad_rbac_enabled = true."
    }
  }

  # The cluster identity needs its permissions before the cluster is created.
  depends_on = [
    azurerm_role_assignment.aks_network_contributor,
    azurerm_role_assignment.aks_kubelet_identity_operator,
  ]
}

# -----------------------------------------------------------------------------
# Additional Node Pools
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = local.node_pools

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = var.subnet_id
  zones                 = length(each.value.zones) > 0 ? each.value.zones : null

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

  # Spot pools are not upgraded by surging.
  dynamic "upgrade_settings" {
    for_each = each.value.priority == "Spot" ? [] : [1]

    content {
      max_surge                     = each.value.max_surge
      drain_timeout_in_minutes      = 30
      node_soak_duration_in_minutes = 0
    }
  }

  tags = merge(var.tags, {
    NodePool = each.value.name
  })

  lifecycle {
    ignore_changes = [node_count]

    precondition {
      condition     = each.value.priority != "Spot" || each.value.mode == "User"
      error_message = "Spot node pool ${each.value.name} must use mode \"User\"."
    }
    precondition {
      condition     = !each.value.enable_auto_scaling || each.value.min_count <= each.value.max_count
      error_message = "Node pool ${each.value.name} needs min_count <= max_count."
    }
  }
}
