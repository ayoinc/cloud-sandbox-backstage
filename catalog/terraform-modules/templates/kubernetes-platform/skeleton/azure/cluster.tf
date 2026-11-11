locals {
  cluster_name = "aks-${var.project_name}-${local.module_environment}-${var.location}"

  # General purpose v5 sizes with premium storage, offered in every region of the form.
  node_vm_sizes = {
    small  = "Standard_D2ls_v5" # 2 vCPU, 4 GiB
    medium = "Standard_D4s_v5"  # 4 vCPU, 16 GiB
    large  = "Standard_D8s_v5"  # 8 vCPU, 32 GiB
  }
}

# -----------------------------------------------------------------------------
# AKS cluster
# -----------------------------------------------------------------------------

#trivy:ignore:AVD-AZU-0041 The pipeline installs the platform components from GitHub-hosted runners, which have no fixed addresses; api_server_authorized_ip_ranges narrows access once the callers are known.
resource "azurerm_kubernetes_cluster" "main" {
  name                = local.cluster_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  dns_prefix          = "${var.project_name}-${local.module_environment}"

  # The name AKS would generate from the resource group and cluster names exceeds the 80 characters allowed.
  node_resource_group = "${module.resource_group.name}-nodes"

  # A minor version: AKS installs its latest patch release and, through the patch channel, later ones.
  kubernetes_version        = var.kubernetes_version
  automatic_channel_upgrade = "patch"
  node_os_channel_upgrade   = "NodeImage"

  # The Standard tier adds the uptime SLA of the control plane.
  sku_tier = local.is_production ? "Standard" : "Free"

  role_based_access_control_enabled = true

  # Issuer and webhook that let Kubernetes service accounts sign in as managed identities (see identity.tf).
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                 = "default"
    vm_size              = local.node_vm_sizes[var.node_size]
    orchestrator_version = var.kubernetes_version
    vnet_subnet_id       = module.network.subnet_ids["aks"]
    zones                = var.availability_zones

    enable_auto_scaling = true
    min_count           = var.node_min_count
    max_count           = max(var.node_min_count, var.node_max_count)

    os_disk_size_gb = 128

    # Lets AKS replace the pool when a property that cannot change in place, such as the VM size, is changed.
    temporary_name_for_rotation = "rotation"

    upgrade_settings {
      max_surge                     = "33%"
      drain_timeout_in_minutes      = 30
      node_soak_duration_in_minutes = 0
    }

    tags = local.common_tags
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [module.cluster_identity.identity_id]
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    pod_cidr            = var.pod_cidr
    service_cidr        = var.service_cidr
    dns_service_ip      = cidrhost(var.service_cidr, 10)
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"

    # NetworkPolicy objects are enforced by the Cilium data plane; without it AKS runs no policy engine.
    network_data_plane = var.enable_network_policies ? "cilium" : "azure"
    network_policy     = var.enable_network_policies ? "cilium" : null
  }

  # People sign in with Microsoft Entra ID and are authorised through Azure role assignments on the cluster.
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = var.cluster_admin_group_object_ids
  }

  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []

    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  tags = local.common_tags

  # The cluster identity must be able to join the subnet before the first node is created.
  depends_on = [module.cluster_identity]
}

# -----------------------------------------------------------------------------
# Control plane logs. Workload logs and metrics are the job of the observability
# stack inside the cluster; the logs of the managed control plane can only be
# collected by Azure.
# -----------------------------------------------------------------------------

module "log_analytics" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/monitoring/log-analytics?ref=${{ values.moduleRef }}"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  project             = var.project_name
  environment         = local.module_environment
  retention_in_days   = local.is_production ? 90 : 30
  tags                = local.common_tags
}

module "control_plane_logs" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/monitoring/diagnostic-settings?ref=${{ values.moduleRef }}"

  project_name               = var.project_name
  environment                = local.module_environment
  name                       = "control-plane"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = module.log_analytics.workspace_id

  enabled_logs = [
    { category = "kube-apiserver" },
    { category = "kube-audit-admin" },
    { category = "kube-controller-manager" },
    { category = "kube-scheduler" },
    { category = "cluster-autoscaler" },
    { category = "guard" },
  ]

  metrics = [
    { category = "AllMetrics" },
  ]
}

# -----------------------------------------------------------------------------
# Interface to the platform components (platform*.tf)
# -----------------------------------------------------------------------------

# Exists once the cluster can schedule pods and its network lets them talk to each other.
resource "terraform_data" "cluster_ready" {
  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_network_security_rule.cluster_internal,
    azurerm_network_security_rule.ingress_web,
    module.external_dns_identity,
  ]
}

locals {
  # Cloud-specific settings of the platform components.
  cloud = {
    name                    = "azure"
    cluster_name            = local.cluster_name
    network_policy_enforced = var.enable_network_policies

    external_dns = {
      provider = "azure"
      service_account_annotations = var.enable_external_dns ? {
        "azure.workload.identity/client-id" = module.external_dns_identity[0].client_id
      } : {}
      values = {
        # The workload identity webhook gives labelled pods the token they exchange for the managed identity.
        podLabels = {
          "azure.workload.identity/use" = "true"
        }
        serviceAccount = {
          labels = {
            "azure.workload.identity/use" = "true"
          }
        }
        # The Azure provider of external-dns reads where its DNS zones are from /etc/kubernetes/azure.json.
        secretConfiguration = {
          enabled   = true
          mountPath = "/etc/kubernetes"
          data = {
            "azure.json" = jsonencode({
              tenantId                     = data.azurerm_client_config.current.tenant_id
              subscriptionId               = data.azurerm_client_config.current.subscription_id
              resourceGroup                = local.dns_zone_resource_group
              useWorkloadIdentityExtension = true
            })
          }
        }
      }
    }

    # ingress-nginx declares its ports as HTTP, which makes Azure probe them with HTTP requests; only /healthz
    # answers 200 without a matching Ingress. Traefik's ports are probed with plain TCP connections.
    ingress_service_annotations = var.ingress_controller == "nginx" ? {
      "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
    } : {}

    # Standard SSD managed disks, created in the zone of the pod that uses them.
    storage_class = "managed-csi"
  }
}
