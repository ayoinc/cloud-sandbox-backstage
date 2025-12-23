# Azure Kubernetes Service (AKS) Module

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  for_each = var.clusters

  name                              = each.key
  location                          = var.location
  resource_group_name               = var.resource_group_name
  dns_prefix                        = each.value.dns_prefix
  kubernetes_version                = each.value.kubernetes_version
  sku_tier                          = each.value.sku_tier
  private_cluster_enabled           = each.value.private_cluster_enabled
  private_dns_zone_id               = each.value.private_dns_zone_id
  automatic_upgrade_channel         = each.value.automatic_upgrade_channel
  node_os_upgrade_channel           = each.value.node_os_upgrade_channel
  azure_policy_enabled              = each.value.azure_policy_enabled
  local_account_disabled            = each.value.local_account_disabled
  oidc_issuer_enabled               = each.value.oidc_issuer_enabled
  workload_identity_enabled         = each.value.workload_identity_enabled
  role_based_access_control_enabled = true
  node_resource_group               = each.value.node_resource_group

  default_node_pool {
    name                         = each.value.default_node_pool.name
    vm_size                      = each.value.default_node_pool.vm_size
    node_count                   = each.value.default_node_pool.node_count
    min_count                    = each.value.default_node_pool.min_count
    max_count                    = each.value.default_node_pool.max_count
    auto_scaling_enabled         = each.value.default_node_pool.auto_scaling_enabled
    max_pods                     = each.value.default_node_pool.max_pods
    os_disk_size_gb              = each.value.default_node_pool.os_disk_size_gb
    os_disk_type                 = each.value.default_node_pool.os_disk_type
    os_sku                       = each.value.default_node_pool.os_sku
    vnet_subnet_id               = each.value.default_node_pool.vnet_subnet_id
    zones                        = each.value.default_node_pool.zones
    only_critical_addons_enabled = each.value.default_node_pool.only_critical_addons_enabled
    temporary_name_for_rotation  = each.value.default_node_pool.temporary_name_for_rotation

    dynamic "upgrade_settings" {
      for_each = each.value.default_node_pool.max_surge != null ? [1] : []
      content {
        max_surge = each.value.default_node_pool.max_surge
      }
    }
  }

  identity {
    type         = each.value.identity_type
    identity_ids = each.value.identity_ids
  }

  dynamic "network_profile" {
    for_each = each.value.network_profile != null ? [each.value.network_profile] : []
    content {
      network_plugin      = network_profile.value.network_plugin
      network_plugin_mode = network_profile.value.network_plugin_mode
      network_policy      = network_profile.value.network_policy
      network_data_plane  = network_profile.value.network_data_plane
      dns_service_ip      = network_profile.value.dns_service_ip
      service_cidr        = network_profile.value.service_cidr
      pod_cidr            = network_profile.value.pod_cidr
      outbound_type       = network_profile.value.outbound_type
      load_balancer_sku   = network_profile.value.load_balancer_sku
    }
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = each.value.aad_rbac != null ? [each.value.aad_rbac] : []
    content {
      azure_rbac_enabled     = azure_active_directory_role_based_access_control.value.azure_rbac_enabled
      admin_group_object_ids = azure_active_directory_role_based_access_control.value.admin_group_object_ids
      tenant_id              = azure_active_directory_role_based_access_control.value.tenant_id
    }
  }

  dynamic "oms_agent" {
    for_each = each.value.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id      = each.value.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = true
    }
  }

  dynamic "microsoft_defender" {
    for_each = each.value.defender_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = each.value.defender_workspace_id
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = each.value.key_vault_secrets_provider_enabled ? [1] : []
    content {
      secret_rotation_enabled  = true
      secret_rotation_interval = "2m"
    }
  }

  dynamic "ingress_application_gateway" {
    for_each = each.value.agic_subnet_id != null ? [1] : []
    content {
      subnet_id = each.value.agic_subnet_id
    }
  }

  dynamic "auto_scaler_profile" {
    for_each = each.value.auto_scaler_profile != null ? [each.value.auto_scaler_profile] : []
    content {
      balance_similar_node_groups      = auto_scaler_profile.value.balance_similar_node_groups
      expander                         = auto_scaler_profile.value.expander
      max_graceful_termination_sec     = auto_scaler_profile.value.max_graceful_termination_sec
      max_node_provisioning_time       = auto_scaler_profile.value.max_node_provisioning_time
      max_unready_nodes                = auto_scaler_profile.value.max_unready_nodes
      max_unready_percentage           = auto_scaler_profile.value.max_unready_percentage
      new_pod_scale_up_delay           = auto_scaler_profile.value.new_pod_scale_up_delay
      scale_down_delay_after_add       = auto_scaler_profile.value.scale_down_delay_after_add
      scale_down_delay_after_delete    = auto_scaler_profile.value.scale_down_delay_after_delete
      scale_down_delay_after_failure   = auto_scaler_profile.value.scale_down_delay_after_failure
      scan_interval                    = auto_scaler_profile.value.scan_interval
      scale_down_unneeded              = auto_scaler_profile.value.scale_down_unneeded
      scale_down_unready               = auto_scaler_profile.value.scale_down_unready
      scale_down_utilization_threshold = auto_scaler_profile.value.scale_down_utilization_threshold
    }
  }

  dynamic "maintenance_window_auto_upgrade" {
    for_each = each.value.maintenance_window != null ? [each.value.maintenance_window] : []
    content {
      frequency   = maintenance_window_auto_upgrade.value.frequency
      interval    = maintenance_window_auto_upgrade.value.interval
      duration    = maintenance_window_auto_upgrade.value.duration
      day_of_week = maintenance_window_auto_upgrade.value.day_of_week
      start_time  = maintenance_window_auto_upgrade.value.start_time
      utc_offset  = maintenance_window_auto_upgrade.value.utc_offset
    }
  }

  dynamic "storage_profile" {
    for_each = each.value.storage_profile != null ? [each.value.storage_profile] : []
    content {
      blob_driver_enabled         = storage_profile.value.blob_driver_enabled
      disk_driver_enabled         = storage_profile.value.disk_driver_enabled
      file_driver_enabled         = storage_profile.value.file_driver_enabled
      snapshot_controller_enabled = storage_profile.value.snapshot_controller_enabled
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each = var.node_pools

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this[each.value.cluster_key].id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  auto_scaling_enabled  = each.value.auto_scaling_enabled
  max_pods              = each.value.max_pods
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  os_sku                = each.value.os_sku
  os_type               = each.value.os_type
  vnet_subnet_id        = each.value.vnet_subnet_id
  zones                 = each.value.zones
  mode                  = each.value.mode
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  priority              = each.value.priority
  eviction_policy       = each.value.eviction_policy
  spot_max_price        = each.value.spot_max_price

  dynamic "upgrade_settings" {
    for_each = each.value.max_surge != null ? [1] : []
    content {
      max_surge = each.value.max_surge
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [node_count]
  }
}
