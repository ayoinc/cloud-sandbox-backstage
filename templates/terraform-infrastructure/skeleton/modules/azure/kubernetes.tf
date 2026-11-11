locals {
  # General-purpose sizes with the requested number of vCPUs.
  node_vm_sizes = {
    small  = "Standard_D2s_v5"
    medium = "Standard_D4s_v5"
    large  = "Standard_D8s_v5"
    xlarge = "Standard_D16s_v5"
  }

  # Cost-optimised environments outside production run their workloads on
  # spot nodes; a single regular node keeps the system components running.
  spot_nodes_enabled      = var.enable_kubernetes && local.economy
  system_pool_autoscaling = var.enable_autoscaling && !local.spot_nodes_enabled
  system_pool_node_count  = local.spot_nodes_enabled ? 1 : var.min_nodes
}

# -----------------------------------------------------------------------------
# Identities of the control plane and of the nodes
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "kubernetes" {
  count = var.enable_kubernetes ? 1 : 0

  name                = "${var.name_prefix}-aks"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = local.tags
}

# The cluster joins its nodes and load balancers to the subnets and links
# the private DNS zone of its API to the virtual network.
resource "azurerm_role_assignment" "kubernetes_network" {
  count = var.enable_kubernetes && local.network_available ? 1 : 0

  scope                = local.network_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.kubernetes[0].principal_id
  principal_type       = "ServicePrincipal"
}

# Nodes pull images with their own identity, which the control plane has to
# be allowed to assign to them.
resource "azurerm_user_assigned_identity" "kubelet" {
  count = var.enable_kubernetes ? 1 : 0

  name                = "${var.name_prefix}-aks-nodes"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = local.tags
}

resource "azurerm_role_assignment" "kubernetes_kubelet" {
  count = var.enable_kubernetes ? 1 : 0

  scope                = azurerm_user_assigned_identity.kubelet[0].id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.kubernetes[0].principal_id
  principal_type       = "ServicePrincipal"
}

# -----------------------------------------------------------------------------
# Cluster
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster" "this" {
  count = var.enable_kubernetes ? 1 : 0

  name                = "${var.name_prefix}-aks"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  node_resource_group = "${var.name_prefix}-aks-nodes-rg"
  dns_prefix          = var.name_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = local.production ? "Standard" : "Free"

  # Without an allow list the API server is reachable from the virtual
  # network only.
  private_cluster_enabled = length(var.kubernetes_api_allowed_cidrs) == 0

  dynamic "api_server_access_profile" {
    for_each = length(var.kubernetes_api_allowed_cidrs) > 0 ? [1] : []

    content {
      authorized_ip_ranges = var.kubernetes_api_allowed_cidrs
    }
  }

  # Users sign in with Microsoft Entra ID and are authorised with Azure role
  # assignments; the shared admin certificate is switched off.
  role_based_access_control_enabled = true
  local_account_disabled            = true

  azure_active_directory_role_based_access_control {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled = true
  }

  # Pods get Azure identities through federated service accounts.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Azure Policy can audit and enforce rules on the workloads.
  azure_policy_enabled = true

  default_node_pool {
    name                         = "system"
    vm_size                      = local.node_vm_sizes[var.node_size]
    vnet_subnet_id               = try(local.private_subnet_ids[0], null)
    zones                        = local.production && local.zonal ? var.availability_zones : null
    only_critical_addons_enabled = local.spot_nodes_enabled
    temporary_name_for_rotation  = "systemtemp"

    auto_scaling_enabled = local.system_pool_autoscaling
    node_count           = local.system_pool_autoscaling ? null : local.system_pool_node_count
    min_count            = local.system_pool_autoscaling ? var.min_nodes : null
    max_count            = local.system_pool_autoscaling ? var.max_nodes : null

    upgrade_settings {
      max_surge = "10%"
    }

    tags = local.tags
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.kubernetes[0].id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet[0].client_id
    object_id                 = azurerm_user_assigned_identity.kubelet[0].principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet[0].id
  }

  # Pods live in an overlay network and do not use addresses of the virtual
  # network. Cilium enforces Kubernetes network policies.
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    pod_cidr            = var.kubernetes_pod_cidr
    service_cidr        = var.kubernetes_service_cidr
    dns_service_ip      = cidrhost(var.kubernetes_service_cidr, 10)
    load_balancer_sku   = "standard"

    # Nodes of a created network leave through its NAT gateways.
    outbound_type = var.enable_networking ? "userAssignedNATGateway" : "loadBalancer"
  }

  # Container logs and inventory go to the Log Analytics workspace.
  dynamic "oms_agent" {
    for_each = var.enable_monitoring ? [1] : []

    content {
      log_analytics_workspace_id      = azurerm_log_analytics_workspace.this[0].id
      msi_auth_for_monitoring_enabled = true
    }
  }

  # Scrapes Prometheus metrics for the Azure Monitor workspace.
  dynamic "monitor_metrics" {
    for_each = var.enable_managed_prometheus ? [1] : []

    content {}
  }

  # Mounts Key Vault secrets into pods through the Secrets Store CSI driver.
  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_secrets_manager ? [1] : []

    content {
      secret_rotation_enabled = true
    }
  }

  tags = local.tags

  lifecycle {
    precondition {
      condition     = length(local.private_subnet_ids) > 0
      error_message = "The Kubernetes cluster needs private subnets: set enable_networking to true or pass existing_network with private_subnet_ids."
    }
  }

  # Nodes need outbound access and the cluster identity its network role
  # while the cluster is created.
  depends_on = [
    azurerm_subnet_nat_gateway_association.private,
    azurerm_nat_gateway_public_ip_association.this,
    azurerm_subnet_network_security_group_association.private,
    azurerm_role_assignment.kubernetes_network,
    azurerm_role_assignment.kubernetes_kubelet,
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  count = local.spot_nodes_enabled ? 1 : 0

  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this[0].id
  mode                  = "User"
  vm_size               = local.node_vm_sizes[var.node_size]
  vnet_subnet_id        = try(element(local.private_subnet_ids, 1), null)

  priority        = "Spot"
  eviction_policy = "Delete"
  spot_max_price  = -1

  auto_scaling_enabled = var.enable_autoscaling
  node_count           = var.enable_autoscaling ? null : var.min_nodes
  min_count            = var.enable_autoscaling ? var.min_nodes : null
  max_count            = var.enable_autoscaling ? var.max_nodes : null

  # AKS puts this label and taint on every spot node; declaring them keeps
  # the plan free of differences.
  node_labels = { "kubernetes.azure.com/scalesetpriority" = "spot" }
  node_taints = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]

  tags = local.tags
}

# -----------------------------------------------------------------------------
# Access
# -----------------------------------------------------------------------------

# Local accounts are disabled, so the identity that creates the cluster
# needs a role to administer it.
resource "azurerm_role_assignment" "kubernetes_admin" {
  count = var.enable_kubernetes ? 1 : 0

  scope                = azurerm_kubernetes_cluster.this[0].id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "kubernetes_registry" {
  count = var.enable_kubernetes && local.registry_enabled ? 1 : 0

  scope                = azurerm_container_registry.this[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.kubelet[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "kubernetes_secrets" {
  count = var.enable_kubernetes && var.enable_secrets_manager ? 1 : 0

  scope                = azurerm_key_vault.this[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.this[0].key_vault_secrets_provider[0].secret_identity[0].object_id
  principal_type       = "ServicePrincipal"
}

# -----------------------------------------------------------------------------
# Container registry
# -----------------------------------------------------------------------------

locals {
  registry_sku = local.production ? "Premium" : (local.economy ? "Basic" : "Standard")
}

# Images are pushed and pulled with Microsoft Entra ID identities: the admin
# user and anonymous pulls are off.
resource "azurerm_container_registry" "this" {
  count = local.registry_enabled ? 1 : 0

  name                = "${local.compact_prefix}${local.suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = local.registry_sku

  admin_enabled           = false
  anonymous_pull_enabled  = false
  zone_redundancy_enabled = local.registry_sku == "Premium" && local.zonal

  # Replicas need the Premium SKU.
  dynamic "georeplications" {
    for_each = local.registry_sku == "Premium" && var.enable_disaster_recovery ? [var.secondary_region] : []

    content {
      location = georeplications.value
      tags     = local.tags
    }
  }

  tags = local.tags
}
