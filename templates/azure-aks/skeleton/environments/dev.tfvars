# =============================================================================
# Development Environment Configuration
# =============================================================================
# Cost-optimized settings for development workloads
# - Smaller node sizes
# - Minimal node counts
# - No spot instances
# - Basic ACR SKU
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "dev"
location    = "${{ values.location }}"
description = "${{ values.description }}"
owner       = "${{ values.owner }}"

# Kubernetes Version
kubernetes_version = "1.28.5"

# System Node Pool - Minimal for dev
system_node_vm_size = "Standard_D2s_v3"
system_node_count   = 1
system_min_count    = 1
system_max_count    = 3

# User Node Pool - Small for dev
create_user_node_pool = true
user_node_vm_size     = "Standard_D2s_v3"
user_node_count       = 1
user_min_count        = 0
user_max_count        = 5
user_node_taints      = []

# Spot Node Pool - Disabled for dev
create_spot_node_pool = false

# Common Node Settings
enable_auto_scaling = true
os_disk_size_gb     = 64
max_surge           = "33%"
availability_zones  = ["1"]

# Network Configuration
network_plugin = "azure"
network_policy = "calico"
outbound_type  = "loadBalancer"
vnet_subnet_id = ""
service_cidr   = "10.0.0.0/16"
dns_service_ip = "10.0.0.10"

# Container Registry - Basic for dev
create_acr = true
acr_sku    = "Basic"
acr_georeplication_locations = []

# Monitoring - Short retention for dev
log_retention_days = 30
enable_defender    = false

# Security
enable_azure_rbac        = true
admin_group_object_ids   = []
enable_workload_identity = true
enable_secret_rotation   = false

# Upgrades - Automatic patch upgrades
automatic_channel_upgrade = "patch"
maintenance_window        = null

# Autoscaler - Aggressive scale down for cost savings
scale_down_delay_after_add       = "5m"
scale_down_unneeded              = "5m"
scale_down_utilization_threshold = "0.7"

# Tags
tags = {
  CostCenter   = "development"
  AutoShutdown = "true"
}
