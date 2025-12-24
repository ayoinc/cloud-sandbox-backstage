# =============================================================================
# GCP GKE - Production Environment Configuration
# =============================================================================
# This file contains Jinja2 template variables that will be substituted
# by Backstage when the template is scaffolded.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables (from Backstage template)
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "prod"
region      = "${{ values.region }}"
project_id  = "${{ values.gcpProject }}"
owner       = "${{ values.owner }}"

# -----------------------------------------------------------------------------
# Cluster Mode - Standard for production (full control)
# -----------------------------------------------------------------------------
cluster_mode = "standard"

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------
network_id          = "${{ values.networkId }}"
subnet_id           = "${{ values.subnetId }}"
pods_range_name     = "pods"
services_range_name = "services"

# -----------------------------------------------------------------------------
# Private Cluster - Private endpoint for production security
# -----------------------------------------------------------------------------
enable_private_endpoint = true
master_ipv4_cidr_block  = "172.16.0.0/28"
master_authorized_networks = [
  {
    cidr_block   = "10.0.0.0/8"
    display_name = "Internal networks"
  }
]

# -----------------------------------------------------------------------------
# Release Channel - Stable for production
# -----------------------------------------------------------------------------
release_channel = "STABLE"

# -----------------------------------------------------------------------------
# Security Configuration
# -----------------------------------------------------------------------------
enable_network_policy = true

# -----------------------------------------------------------------------------
# Cluster Autoscaling (NAP)
# -----------------------------------------------------------------------------
enable_cluster_autoscaling = true
autoscaling_cpu_min        = 4
autoscaling_cpu_max        = 200
autoscaling_memory_min     = 8
autoscaling_memory_max     = 500

# -----------------------------------------------------------------------------
# Node Pool Configuration
# -----------------------------------------------------------------------------
node_count            = 3
node_pool_min_count   = 3
node_pool_max_count   = 20
machine_type          = "e2-standard-8"
disk_size_gb          = 200
disk_type             = "pd-ssd"
image_type            = "COS_CONTAINERD"
use_preemptible_nodes = false
use_spot_nodes        = false

# -----------------------------------------------------------------------------
# Node Pool Upgrade - Conservative for production
# -----------------------------------------------------------------------------
max_surge       = 1
max_unavailable = 0

# -----------------------------------------------------------------------------
# Node Taints
# -----------------------------------------------------------------------------
node_taints = []

# -----------------------------------------------------------------------------
# Additional Node Pools - Example high-memory pool for production
# -----------------------------------------------------------------------------
additional_node_pools = {
  # Uncomment to add a high-memory node pool
  # high-memory = {
  #   node_count   = 2
  #   min_count    = 2
  #   max_count    = 10
  #   machine_type = "n2-highmem-8"
  #   disk_size_gb = 200
  #   disk_type    = "pd-ssd"
  #   preemptible  = false
  #   spot         = false
  #   labels = {
  #     workload-type = "memory-intensive"
  #   }
  #   taints = []
  # }
}

# -----------------------------------------------------------------------------
# Maintenance Window - Early morning on weekends
# -----------------------------------------------------------------------------
maintenance_start_time = "2024-01-01T02:00:00Z"
maintenance_end_time   = "2024-01-01T06:00:00Z"
maintenance_recurrence = "FREQ=WEEKLY;BYDAY=SA"

# -----------------------------------------------------------------------------
# Artifact Registry
# -----------------------------------------------------------------------------
create_artifact_registry     = true
artifact_registry_keep_count = 20

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------
labels = {
  cost-center = "production"
  team        = "${{ values.owner }}"
  criticality = "high"
}
