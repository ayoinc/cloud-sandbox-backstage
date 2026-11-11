# -----------------------------------------------------------------------------
# Application tier: one of an AKS cluster, a virtual machine scale set or a
# Container App, chosen by compute_type. All of them sit in the application
# subnet behind the Application Gateway.
# -----------------------------------------------------------------------------

# --- aks ----------------------------------------------------------------------

locals {
  # Pod and service addresses must not overlap the virtual network, which lies
  # in one of the three private address blocks.
  kubernetes_pod_cidr     = coalesce(var.kubernetes_pod_cidr, startswith(local.vnet_address_space, "192.168.") ? "10.244.0.0/16" : "192.168.0.0/16")
  kubernetes_service_cidr = coalesce(var.kubernetes_service_cidr, startswith(local.vnet_address_space, "172.") ? "10.0.0.0/16" : "172.16.0.0/16")
}

resource "azurerm_user_assigned_identity" "aks" {
  count = local.runs_aks ? 1 : 0

  name                = "id-aks-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = local.common_tags
}

# The cluster joins its nodes to the application subnet and creates the
# internal load balancer of its ingress in the ingress subnet.
resource "azurerm_role_assignment" "aks_network" {
  count = local.runs_aks ? 1 : 0

  scope                            = module.network.vnet_id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.aks[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_kubernetes_cluster" "main" {
  count = local.runs_aks ? 1 : 0

  name                      = "aks-${local.name_prefix}"
  resource_group_name       = module.resource_group.name
  location                  = var.location
  dns_prefix                = "aks-${local.name_prefix}"
  node_resource_group       = "${module.resource_group.name}-aks-nodes"
  kubernetes_version        = var.kubernetes_version
  sku_tier                  = local.is_production ? "Standard" : "Free"
  automatic_channel_upgrade = "patch"

  # The API server has no public endpoint unless address ranges are allowed.
  private_cluster_enabled = length(var.aks_authorized_ip_ranges) == 0

  dynamic "api_server_access_profile" {
    for_each = length(var.aks_authorized_ip_ranges) > 0 ? [var.aks_authorized_ip_ranges] : []

    content {
      authorized_ip_ranges = api_server_access_profile.value
    }
  }

  # Access to the cluster is granted with Microsoft Entra ID and Azure roles.
  local_account_disabled            = true
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true

  default_node_pool {
    name                        = "default"
    vm_size                     = var.vm_size
    vnet_subnet_id              = module.network.subnet_ids["app"]
    enable_auto_scaling         = true
    min_count                   = var.min_nodes
    max_count                   = local.max_nodes
    zones                       = local.availability_zones
    temporary_name_for_rotation = "rotation"
    tags                        = local.common_tags
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks[0].id]
  }

  # Pods get addresses from an overlay network, so a node takes one address of
  # the application subnet whatever the number of pods.
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    pod_cidr            = local.kubernetes_pod_cidr
    service_cidr        = local.kubernetes_service_cidr
    dns_service_ip      = cidrhost(local.kubernetes_service_cidr, 10)
    load_balancer_sku   = "standard"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = var.aks_admin_group_object_ids
  }

  oms_agent {
    log_analytics_workspace_id      = module.log_analytics.workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  tags = local.common_tags

  depends_on = [azurerm_role_assignment.aks_network]
}

# --- vmss ---------------------------------------------------------------------

locals {
  vmss_cloud_init = <<-EOT
    #cloud-config
    package_update: true
    packages:
      - nginx
    write_files:
      - path: /etc/nginx/sites-available/default
        defer: true
        content: |
          server {
            listen ${var.app_port} default_server;
            root /var/www/html;
            index index.html index.nginx-debian.html;
          }
    runcmd:
      - systemctl enable nginx
      - systemctl restart nginx
  EOT
}

# The instances have no public address. They reach the internet, for packages
# and updates, through a NAT gateway.
module "nat_gateway" {
  count  = local.runs_vmss ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/network/nat-gateway?ref=${{ values.moduleRef }}"

  project_name        = var.project_name
  environment         = local.environment_short
  resource_group_name = module.resource_group.name
  location            = var.location
  name                = "nat"
  subnet_ids          = [module.network.subnet_ids["app"]]
  tags                = local.common_tags
}

resource "tls_private_key" "vmss" {
  count = local.runs_vmss && var.vmss_admin_ssh_public_key == null ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine_scale_set" "app" {
  count = local.runs_vmss ? 1 : 0

  name                = "vmss-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = var.location
  sku                 = var.vm_size
  instances           = var.min_nodes
  zones               = local.availability_zones
  upgrade_mode        = "Automatic"
  admin_username      = var.vmss_admin_username
  custom_data         = base64encode(coalesce(var.vmss_custom_data, local.vmss_cloud_init))

  admin_ssh_key {
    username   = var.vmss_admin_username
    public_key = coalesce(var.vmss_admin_ssh_public_key, one(tls_private_key.vmss[*].public_key_openssh))
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "StandardSSD_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "primary"
    primary = true

    ip_configuration {
      name                                         = "internal"
      primary                                      = true
      subnet_id                                    = module.network.subnet_ids["app"]
      application_gateway_backend_address_pool_ids = azurerm_application_gateway.main.backend_address_pool[*].id
    }
  }

  # Instances that stop answering on the application port are replaced.
  extension {
    name                       = "ApplicationHealth"
    publisher                  = "Microsoft.ManagedServices"
    type                       = "ApplicationHealthLinux"
    type_handler_version       = "1.0"
    auto_upgrade_minor_version = true

    settings = jsonencode({
      protocol    = "http"
      port        = var.app_port
      requestPath = var.health_check_path
    })
  }

  automatic_instance_repair {
    enabled      = true
    grace_period = "PT30M"
  }

  tags = local.common_tags

  # The number of instances is managed by the autoscale setting.
  lifecycle {
    ignore_changes = [instances]
  }

  depends_on = [module.nat_gateway]
}

resource "azurerm_monitor_autoscale_setting" "app" {
  count = local.runs_vmss ? 1 : 0

  name                = "autoscale-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.app[0].id

  profile {
    name = "cpu"

    capacity {
      default = var.min_nodes
      minimum = var.min_nodes
      maximum = local.max_nodes
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.app[0].id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.cpu_target
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.app[0].id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.cpu_target / 2
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = local.common_tags
}

# --- container-apps -----------------------------------------------------------

# The environment is reachable from the virtual network only.
resource "azurerm_container_app_environment" "main" {
  count = local.runs_container_apps ? 1 : 0

  name                               = "cae-${local.name_prefix}"
  resource_group_name                = module.resource_group.name
  location                           = var.location
  log_analytics_workspace_id         = module.log_analytics.workspace_id
  infrastructure_subnet_id           = module.network.subnet_ids["app"]
  infrastructure_resource_group_name = "${module.resource_group.name}-container-apps"
  internal_load_balancer_enabled     = true
  zone_redundancy_enabled            = local.is_production

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  tags = local.common_tags
}

resource "azurerm_container_app" "app" {
  count = local.runs_container_apps ? 1 : 0

  name                         = "ca-${local.name_prefix}"
  resource_group_name          = module.resource_group.name
  container_app_environment_id = azurerm_container_app_environment.main[0].id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  template {
    min_replicas = var.min_nodes
    max_replicas = local.max_nodes

    container {
      name   = "app"
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "DATABASE_ENDPOINT"
        value = local.database_endpoint
      }
    }

    http_scale_rule {
      name                = "http"
      concurrent_requests = tostring(var.container_concurrent_requests)
    }
  }

  ingress {
    external_enabled           = true
    target_port                = var.app_port
    transport                  = "auto"
    allow_insecure_connections = false

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = local.common_tags
}

# Names in the environment's domain resolve to its internal load balancer for
# everything in the virtual network, including the Application Gateway.
resource "azurerm_private_dns_zone" "container_apps" {
  count = local.runs_container_apps ? 1 : 0

  name                = azurerm_container_app_environment.main[0].default_domain
  resource_group_name = module.resource_group.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "container_apps" {
  count = local.runs_container_apps ? 1 : 0

  name                  = "vnet"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.container_apps[0].name
  virtual_network_id    = module.network.vnet_id
  tags                  = local.common_tags
}

resource "azurerm_private_dns_a_record" "container_apps" {
  count = local.runs_container_apps ? 1 : 0

  name                = "*"
  zone_name           = azurerm_private_dns_zone.container_apps[0].name
  resource_group_name = module.resource_group.name
  ttl                 = 300
  records             = [azurerm_container_app_environment.main[0].static_ip_address]
  tags                = local.common_tags
}
