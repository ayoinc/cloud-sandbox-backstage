# =============================================================================
# Azure AKS - Root Module
# =============================================================================
# This is the root module that instantiates the AKS child module.
# All environment-specific values are passed via -var-file.
# =============================================================================

module "aks" {
  source = "./modules/aks"

  # Required variables
  name               = var.name
  environment        = var.environment
  location           = var.location
  description        = var.description
  owner              = var.owner
  kubernetes_version = var.kubernetes_version

  # System Node Pool
  system_node_vm_size = var.system_node_vm_size
  system_node_count   = var.system_node_count
  system_min_count    = var.system_min_count
  system_max_count    = var.system_max_count

  # User Node Pool
  create_user_node_pool = var.create_user_node_pool
  user_node_vm_size     = var.user_node_vm_size
  user_node_count       = var.user_node_count
  user_min_count        = var.user_min_count
  user_max_count        = var.user_max_count
  user_node_taints      = var.user_node_taints

  # Spot Node Pool
  create_spot_node_pool = var.create_spot_node_pool
  spot_node_vm_size     = var.spot_node_vm_size
  spot_node_count       = var.spot_node_count
  spot_max_count        = var.spot_max_count
  spot_max_price        = var.spot_max_price

  # Common Node Settings
  enable_auto_scaling = var.enable_auto_scaling
  os_disk_size_gb     = var.os_disk_size_gb
  max_surge           = var.max_surge
  availability_zones  = var.availability_zones

  # Network Configuration
  network_plugin = var.network_plugin
  network_policy = var.network_policy
  outbound_type  = var.outbound_type
  vnet_subnet_id = var.vnet_subnet_id
  service_cidr   = var.service_cidr
  dns_service_ip = var.dns_service_ip

  # Container Registry
  create_acr                   = var.create_acr
  acr_sku                      = var.acr_sku
  acr_georeplication_locations = var.acr_georeplication_locations

  # Monitoring
  log_retention_days = var.log_retention_days
  enable_defender    = var.enable_defender

  # Security
  enable_azure_rbac        = var.enable_azure_rbac
  admin_group_object_ids   = var.admin_group_object_ids
  enable_workload_identity = var.enable_workload_identity
  enable_secret_rotation   = var.enable_secret_rotation
  secret_rotation_interval = var.secret_rotation_interval

  # Upgrades
  automatic_channel_upgrade = var.automatic_channel_upgrade
  maintenance_window        = var.maintenance_window

  # Autoscaler
  scale_down_delay_after_add       = var.scale_down_delay_after_add
  scale_down_unneeded              = var.scale_down_unneeded
  scale_down_utilization_threshold = var.scale_down_utilization_threshold

  # Tags
  tags = var.tags
}
