# =============================================================================
# Production Environment Configuration
# =============================================================================
# Full production settings with high availability
# - Large node sizes
# - Higher node counts
# - All availability zones
# - Premium ACR with geo-replication
# - Enhanced security and monitoring
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "prod"
location    = "${{ values.location }}"
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

# Kubernetes Version (minor version; AKS selects the latest patch)
kubernetes_version = "${{ values.kubernetesVersion }}"

# System Node Pool - Production scale
system_node_vm_size = "Standard_D4s_v3"
system_node_count   = 3
system_min_count    = 3
system_max_count    = 10

{% set fromForm = values.envName == 'prod' -%}
# User Node Pool - Production scale{% if fromForm %} (sized from the template form){% endif %}
create_user_node_pool = true
user_node_vm_size     = "${{ values.nodeVmSize if fromForm else 'Standard_D8s_v3' }}"
user_node_count       = ${{ values.nodeCount if fromForm else 3 }}
user_min_count        = ${{ ([values.nodeCount, 2] | sort | first) if fromForm else 2 }}
user_max_count        = ${{ ([values.nodeCount, values.maxNodeCount] | sort | last) if fromForm else 20 }}
user_node_taints      = []

# Spot Node Pool - For batch/non-critical workloads
create_spot_node_pool = true
spot_node_vm_size     = "Standard_D4s_v3"
spot_node_count       = 0
spot_max_count        = 10
spot_max_price        = -1

# Common Node Settings
enable_auto_scaling = true
os_disk_size_gb     = 256
max_surge           = "10%"
availability_zones  = ["1", "2", "3"]

# Network Configuration
network_plugin = "azure"
network_policy = "calico"
outbound_type  = "loadBalancer"
vnet_subnet_id = ""
service_cidr   = "10.0.0.0/16"
dns_service_ip = "10.0.0.10"

# Container Registry - Premium for production
create_acr                   = true
acr_sku                      = "Premium"
acr_georeplication_locations = [] # Add secondary regions if needed

# Monitoring - Extended retention
log_retention_days = 90
enable_defender    = true

# Security
enable_azure_rbac        = true
admin_group_object_ids   = [] # Add Azure AD group IDs for admin access
enable_workload_identity = true
enable_secret_rotation   = true
secret_rotation_interval = "2m"

# Upgrades - Controlled upgrades
automatic_channel_upgrade = "stable"
maintenance_window = {
  day   = "Sunday"
  hours = [2, 3, 4, 5]
}

# Autoscaler - Conservative settings for stability
scale_down_delay_after_add       = "15m"
scale_down_unneeded              = "15m"
scale_down_utilization_threshold = "0.4"

# Tags
tags = {
  CostCenter    = "production"
  Criticality   = "high"
  Compliance    = "required"
  BackupEnabled = "true"
}
