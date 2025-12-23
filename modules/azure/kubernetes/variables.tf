variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "clusters" {
  type = map(object({
    dns_prefix                         = string
    kubernetes_version                 = optional(string)
    sku_tier                           = optional(string, "Standard")
    private_cluster_enabled            = optional(bool, true)
    private_dns_zone_id                = optional(string)
    automatic_upgrade_channel          = optional(string, "patch")
    node_os_upgrade_channel            = optional(string, "NodeImage")
    azure_policy_enabled               = optional(bool, true)
    local_account_disabled             = optional(bool, true)
    oidc_issuer_enabled                = optional(bool, true)
    workload_identity_enabled          = optional(bool, true)
    node_resource_group                = optional(string)
    identity_type                      = optional(string, "SystemAssigned")
    identity_ids                       = optional(list(string))
    log_analytics_workspace_id         = optional(string)
    defender_workspace_id              = optional(string)
    key_vault_secrets_provider_enabled = optional(bool, true)
    agic_subnet_id                     = optional(string)

    default_node_pool = object({
      name                         = optional(string, "system")
      vm_size                      = optional(string, "Standard_D4s_v5")
      node_count                   = optional(number, 3)
      min_count                    = optional(number, 3)
      max_count                    = optional(number, 10)
      auto_scaling_enabled         = optional(bool, true)
      max_pods                     = optional(number, 50)
      os_disk_size_gb              = optional(number, 128)
      os_disk_type                 = optional(string, "Ephemeral")
      os_sku                       = optional(string, "AzureLinux")
      vnet_subnet_id               = string
      zones                        = optional(list(string), ["1", "2", "3"])
      only_critical_addons_enabled = optional(bool, true)
      temporary_name_for_rotation  = optional(string, "tempsystem")
      max_surge                    = optional(string, "33%")
    })

    network_profile = optional(object({
      network_plugin      = optional(string, "azure")
      network_plugin_mode = optional(string, "overlay")
      network_policy      = optional(string, "cilium")
      network_data_plane  = optional(string, "cilium")
      dns_service_ip      = optional(string)
      service_cidr        = optional(string)
      pod_cidr            = optional(string)
      outbound_type       = optional(string, "userDefinedRouting")
      load_balancer_sku   = optional(string, "standard")
    }))

    aad_rbac = optional(object({
      azure_rbac_enabled     = optional(bool, true)
      admin_group_object_ids = optional(list(string), [])
      tenant_id              = optional(string)
    }))

    auto_scaler_profile = optional(object({
      balance_similar_node_groups      = optional(bool, true)
      expander                         = optional(string, "least-waste")
      max_graceful_termination_sec     = optional(string, "600")
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
      scale_down_utilization_threshold = optional(string, "0.5")
    }))

    maintenance_window = optional(object({
      frequency   = optional(string, "Weekly")
      interval    = optional(number, 1)
      duration    = optional(number, 4)
      day_of_week = optional(string, "Sunday")
      start_time  = optional(string, "02:00")
      utc_offset  = optional(string, "+00:00")
    }))

    storage_profile = optional(object({
      blob_driver_enabled         = optional(bool, true)
      disk_driver_enabled         = optional(bool, true)
      file_driver_enabled         = optional(bool, true)
      snapshot_controller_enabled = optional(bool, true)
    }))
  }))
  default = {}
}

variable "node_pools" {
  type = map(object({
    cluster_key          = string
    name                 = string
    vm_size              = optional(string, "Standard_D4s_v5")
    node_count           = optional(number, 3)
    min_count            = optional(number, 1)
    max_count            = optional(number, 10)
    auto_scaling_enabled = optional(bool, true)
    max_pods             = optional(number, 50)
    os_disk_size_gb      = optional(number, 128)
    os_disk_type         = optional(string, "Ephemeral")
    os_sku               = optional(string, "AzureLinux")
    os_type              = optional(string, "Linux")
    vnet_subnet_id       = string
    zones                = optional(list(string), ["1", "2", "3"])
    mode                 = optional(string, "User")
    node_labels          = optional(map(string), {})
    node_taints          = optional(list(string), [])
    priority             = optional(string, "Regular")
    eviction_policy      = optional(string)
    spot_max_price       = optional(number)
    max_surge            = optional(string, "33%")
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
