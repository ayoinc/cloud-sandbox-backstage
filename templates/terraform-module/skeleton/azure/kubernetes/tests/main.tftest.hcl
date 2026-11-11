mock_provider "azurerm" {}

variables {
  project_name        = "demo-platform-services"
  environment         = "dev"
  location            = "eastus2"
  resource_group_name = "demo-dev-rg"
  subnet_id           = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.Network/virtualNetworks/demo-vnet/subnets/kubernetes"
}

run "defaults" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.main.name == "demo-platform-services-dev-aks" && azurerm_kubernetes_cluster.main.node_resource_group == "demo-platform-services-dev-aks-nodes-rg"
    error_message = "Cluster and node resource group names must derive from project and environment."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.private_cluster_enabled && length(azurerm_kubernetes_cluster.main.api_server_access_profile) == 0
    error_message = "The API server must be private by default."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.role_based_access_control_enabled && azurerm_kubernetes_cluster.main.local_account_disabled == false
    error_message = "Kubernetes RBAC must be on; local accounts stay until Entra ID sign-in is enabled."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.network_profile[0].network_plugin_mode == "overlay" && azurerm_kubernetes_cluster.main.network_profile[0].network_policy == "cilium" && azurerm_kubernetes_cluster.main.network_profile[0].network_data_plane == "cilium"
    error_message = "Azure CNI Overlay with Cilium is the default network."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.default_node_pool[0].vm_size == "Standard_D2s_v5" && azurerm_kubernetes_cluster.main.default_node_pool[0].auto_scaling_enabled && azurerm_kubernetes_cluster.main.default_node_pool[0].min_count == 1 && azurerm_kubernetes_cluster.main.default_node_pool[0].max_count == 5
    error_message = "The default node pool must autoscale between 1 and 5 nodes."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.default_node_pool[0].vnet_subnet_id == var.subnet_id && azurerm_role_assignment.aks_network_contributor.scope == var.subnet_id
    error_message = "Nodes join the subnet and the identity is scoped to it."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.workload_identity_enabled && azurerm_kubernetes_cluster.main.oidc_issuer_enabled && azurerm_kubernetes_cluster.main.azure_policy_enabled
    error_message = "Workload identity and Azure Policy must be on by default."
  }

  assert {
    condition     = length(azurerm_kubernetes_cluster.main.key_vault_secrets_provider) == 1 && length(azurerm_kubernetes_cluster.main.oms_agent) == 0 && length(azurerm_kubernetes_cluster.main.azure_active_directory_role_based_access_control) == 0
    error_message = "Secrets provider on; Container Insights and Entra ID off by default."
  }

  assert {
    condition     = length(azurerm_kubernetes_cluster_node_pool.additional) == 0 && length(azurerm_role_assignment.aks_acr_pull) == 0
    error_message = "No additional pools or registry assignment by default."
  }
}

run "public_cluster_with_all_features" {
  command = plan

  variables {
    private_cluster_enabled         = false
    api_server_authorized_ip_ranges = ["203.0.113.0/24"]
    kubernetes_version              = "1.34"
    azure_ad_rbac_enabled           = true
    azure_rbac_enabled              = true
    admin_group_object_ids          = ["11111111-1111-1111-1111-111111111111"]
    log_analytics_workspace_id      = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.OperationalInsights/workspaces/demo-law"
    acr_id                          = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.ContainerRegistry/registries/demoacr"
    outbound_type                   = "userAssignedNATGateway"
    maintenance_window              = { allowed = [{ day = "Sunday", hours = [0, 1, 2] }] }
    default_node_pool               = { zones = ["1", "2", "3"], only_critical_addons_enabled = true }
    additional_node_pools = [
      { name = "user", vm_size = "Standard_D4s_v5", min_count = 1, max_count = 4 },
      { name = "spot", priority = "Spot", enable_auto_scaling = false, node_count = 2 },
    ]
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.api_server_access_profile[0].authorized_ip_ranges == toset(["203.0.113.0/24"])
    error_message = "The public API server must be limited to the allow-list."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.local_account_disabled && azurerm_kubernetes_cluster.main.azure_active_directory_role_based_access_control[0].azure_rbac_enabled
    error_message = "Entra ID sign-in must disable local accounts and enable Azure RBAC."
  }

  assert {
    condition     = length(azurerm_kubernetes_cluster.main.oms_agent) == 1 && length(azurerm_role_assignment.aks_acr_pull) == 1
    error_message = "Container Insights and the AcrPull assignment must be created."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.default_node_pool[0].zones == toset(["1", "2", "3"]) && azurerm_kubernetes_cluster.main.default_node_pool[0].only_critical_addons_enabled
    error_message = "Default pool overrides must be applied."
  }

  assert {
    condition     = azurerm_kubernetes_cluster_node_pool.additional["user"].auto_scaling_enabled && azurerm_kubernetes_cluster_node_pool.additional["user"].max_count == 4 && length(azurerm_kubernetes_cluster_node_pool.additional["user"].upgrade_settings) == 1
    error_message = "The user pool must autoscale up to 4 nodes."
  }

  assert {
    condition     = azurerm_kubernetes_cluster_node_pool.additional["spot"].priority == "Spot" && azurerm_kubernetes_cluster_node_pool.additional["spot"].eviction_policy == "Delete" && azurerm_kubernetes_cluster_node_pool.additional["spot"].node_count == 2 && length(azurerm_kubernetes_cluster_node_pool.additional["spot"].upgrade_settings) == 0
    error_message = "The spot pool must be a fixed-size Spot pool without surge settings."
  }
}

run "node_subnet_networking_with_calico" {
  command = plan

  variables {
    network_plugin_mode = null
    network_policy      = "calico"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.network_profile[0].network_policy == "calico" && azurerm_kubernetes_cluster.main.network_profile[0].network_data_plane == "azure"
    error_message = "Calico must run on the Azure data plane."
  }
}

run "rejects_public_cluster_without_allow_list" {
  command = plan

  variables {
    private_cluster_enabled = false
  }

  expect_failures = [azurerm_kubernetes_cluster.main]
}

run "rejects_cilium_without_overlay" {
  command = plan

  variables {
    network_plugin_mode = null
  }

  expect_failures = [azurerm_kubernetes_cluster.main]
}

run "rejects_long_node_pool_name" {
  command = plan

  variables {
    additional_node_pools = [{ name = "averylongpoolname" }]
  }

  expect_failures = [var.additional_node_pools]
}
