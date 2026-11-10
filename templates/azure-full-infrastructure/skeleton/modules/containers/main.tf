# =============================================================================
# Containers Module
# =============================================================================
# Azure Container Registry and an AKS cluster with a system and a user node
# pool that pulls its images from it.
# =============================================================================

locals {
  prefix = "${var.name}-${var.environment}"

  # Registry names consist of letters and digits only.
  acr_name = lower(replace("acr${var.name}${var.environment}", "-", ""))

  premium_registry = var.acr_sku == "Premium"
}

# -----------------------------------------------------------------------------
# Container Registry
# -----------------------------------------------------------------------------
resource "azurerm_container_registry" "main" {
  #checkov:skip=CKV_AZURE_139:The registry keeps its public endpoint so pipelines can push images; pulls need the AcrPull role and the admin user is disabled
  #checkov:skip=CKV_AZURE_233:Zone redundancy exists only in the Premium SKU and is switched on with it below
  #checkov:skip=CKV_AZURE_237:Dedicated data endpoints exist only in the Premium SKU and matter only behind a firewall
  #checkov:skip=CKV_AZURE_165:Geo-replication to the secondary region is switched on with disaster recovery (Premium SKU)
  #checkov:skip=CKV_AZURE_164:Content trust exists only in the Premium SKU and is being retired by Azure
  #checkov:skip=CKV_AZURE_166:Image quarantine is a preview feature of the Premium SKU
  name                = local.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = false

  # Zone redundancy, replication and untagged-manifest cleanup exist only in
  # the Premium SKU.
  zone_redundancy_enabled = local.premium_registry && var.enable_high_availability

  dynamic "georeplications" {
    for_each = local.premium_registry && var.georeplication_location != null ? [var.georeplication_location] : []

    content {
      location                = georeplications.value
      zone_redundancy_enabled = false
      tags                    = var.tags
    }
  }

  dynamic "retention_policy" {
    for_each = local.premium_registry ? [1] : []

    content {
      days    = 7
      enabled = true
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Cluster Identities
# -----------------------------------------------------------------------------
# One identity for the control plane and one for the kubelets, created up front
# so their role assignments exist before the cluster does.
resource "azurerm_user_assigned_identity" "cluster" {
  name                = "id-aks-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "kubelet" {
  name                = "id-aks-kubelet-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# AKS Cluster
# -----------------------------------------------------------------------------
#trivy:ignore:AZU-0040 Container Insights is switched on together with the Monitoring module, which provides the workspace
#trivy:ignore:AZU-0065 The API server is public by default so kubectl works without a VNet connection; set private_cluster_enabled to change it
#trivy:ignore:AZU-0041 API access is open by default and protected by Entra ID with Azure RBAC; set api_server_authorized_ip_ranges to restrict it
resource "azurerm_kubernetes_cluster" "main" {
  #checkov:skip=CKV_AZURE_115:The API server is public by default so kubectl works without a VNet connection; set private_cluster_enabled to change it
  #checkov:skip=CKV_AZURE_6:API access is open by default and protected by Entra ID with Azure RBAC; set api_server_authorized_ip_ranges to restrict it
  #checkov:skip=CKV_AZURE_117:Node disks use platform-managed keys; a disk encryption set needs a customer-managed key in Key Vault
  #checkov:skip=CKV_AZURE_226:Ephemeral OS disks need a VM cache larger than the OS disk, which the default D-series sizes lack
  #checkov:skip=CKV_AZURE_227:Encryption at host needs the EncryptionAtHost feature registered on the subscription; set enable_host_encryption once it is
  #checkov:skip=CKV_AZURE_170:The Standard tier with its uptime SLA is selected together with high availability; the Free tier keeps other environments cheap
  name                = "aks-${local.prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = local.prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.enable_high_availability ? "Standard" : "Free"

  automatic_channel_upgrade = "patch"

  # API server exposure
  private_cluster_enabled = var.private_cluster_enabled

  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []

    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  # Sign-in goes through Entra ID only; no shared admin certificate
  local_account_disabled = true

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  # Azure Policy add-on (Gatekeeper)
  azure_policy_enabled = true

  # Key Vault secrets as volumes, re-read when a secret changes
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  # System pool: runs only the cluster's own components
  default_node_pool {
    name                         = "system"
    vm_size                      = var.node_vm_size
    node_count                   = var.enable_high_availability ? 3 : 1
    only_critical_addons_enabled = true
    max_pods                     = 50
    os_disk_size_gb              = 128
    enable_host_encryption       = var.enable_host_encryption
    vnet_subnet_id               = var.vnet_subnet_id
    zones                        = var.enable_high_availability ? ["1", "2", "3"] : null

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cluster.id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = var.service_cidr
    dns_service_ip    = cidrhost(var.service_cidr, 10)
  }

  dynamic "oms_agent" {
    for_each = var.enable_container_insights ? [1] : []

    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  tags = var.tags

  # The cluster identity must hold its roles before the cluster is created.
  depends_on = [
    azurerm_role_assignment.kubelet_identity_operator,
    azurerm_role_assignment.network_contributor,
  ]
}

# User pool: runs the workloads and scales with them
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  #checkov:skip=CKV_AZURE_227:Encryption at host needs the EncryptionAtHost feature registered on the subscription; set enable_host_encryption once it is
  name                   = "user"
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.main.id
  mode                   = "User"
  vm_size                = var.node_vm_size
  enable_auto_scaling    = true
  node_count             = var.node_count
  min_count              = var.min_node_count
  max_count              = var.max_node_count
  max_pods               = 50
  os_disk_size_gb        = 128
  enable_host_encryption = var.enable_host_encryption
  vnet_subnet_id         = var.vnet_subnet_id
  zones                  = var.enable_high_availability ? ["1", "2", "3"] : null

  upgrade_settings {
    max_surge = "33%"
  }

  lifecycle {
    # The autoscaler owns the node count after creation.
    ignore_changes = [node_count]
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Role Assignments
# -----------------------------------------------------------------------------
# The cluster identity assigns the kubelet identity to the nodes.
resource "azurerm_role_assignment" "kubelet_identity_operator" {
  scope                            = azurerm_user_assigned_identity.kubelet.id
  role_definition_name             = "Managed Identity Operator"
  principal_id                     = azurerm_user_assigned_identity.cluster.principal_id
  skip_service_principal_aad_check = true
}

# The cluster identity manages load balancers and routes in its subnet.
resource "azurerm_role_assignment" "network_contributor" {
  count = var.enable_vnet_integration ? 1 : 0

  scope                            = var.vnet_subnet_id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.cluster.principal_id
  skip_service_principal_aad_check = true
}

# The kubelet identity pulls images from the registry.
resource "azurerm_role_assignment" "acr_pull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_user_assigned_identity.kubelet.principal_id
  skip_service_principal_aad_check = true
}
