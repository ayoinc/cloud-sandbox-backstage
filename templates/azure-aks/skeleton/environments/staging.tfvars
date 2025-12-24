# =============================================================================
# Staging Environment Configuration
# =============================================================================
# Production-like settings for staging/testing workloads
# - Medium node sizes
# - Moderate node counts
# - Multi-zone deployment
# - Standard ACR SKU
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "staging"
location    = "${{ values.location }}"
description = "${{ values.description }}"
owner       = "${{ values.owner }}"

# Kubernetes Version
kubernetes_version = "1.28.5"

# System Node Pool - Production-like
system_node_vm_size = "Standard_D4s_v3"
system_node_count   = 2
system_min_count    = 2
system_max_count    = 5

# User Node Pool - Production-like
create_user_node_pool = true
user_node_vm_size     = "Standard_D4s_v3"
user_node_count       = 2
user_min_count        = 1
user_max_count        = 10
user_node_taints      = []

# Spot Node Pool - Optional for staging
create_spot_node_pool = true
spot_node_vm_size     = "Standard_D4s_v3"
spot_node_count       = 0
spot_max_count        = 5
spot_max_price        = -1

# Common Node Settings
enable_auto_scaling = true
os_disk_size_gb     = 128
max_surge           = "10%"
availability_zones  = ["1", "2"]

# Network Configuration
network_plugin = "azure"
network_policy = "calico"
outbound_type  = "loadBalancer"
vnet_subnet_id = ""
service_cidr   = "10.0.0.0/16"
dns_service_ip = "10.0.0.10"

# Container Registry - Standard for staging
create_acr = true
acr_sku    = "Standard"
acr_georeplication_locations = []

# Monitoring
log_retention_days = 60
enable_defender    = false

# Security
enable_azure_rbac        = true
admin_group_object_ids   = []
enable_workload_identity = true
enable_secret_rotation   = true
secret_rotation_interval = "2m"

# Upgrades
automatic_channel_upgrade = "patch"
maintenance_window = {
  day   = "Saturday"
  hours = [2, 3, 4]
}

# Autoscaler - Balanced settings
scale_down_delay_after_add       = "10m"
scale_down_unneeded              = "10m"
scale_down_utilization_threshold = "0.5"

# Tags
tags = {
  CostCenter = "staging"
  Testing    = "true"
}
