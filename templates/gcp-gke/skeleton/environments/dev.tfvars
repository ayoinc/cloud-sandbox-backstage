# =============================================================================
# GCP GKE - Development Environment Configuration
# =============================================================================
# This file contains Jinja2 template variables that will be substituted
# by Backstage when the template is scaffolded.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables (from Backstage template)
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "dev"
region      = "${{ values.region }}"
project_id  = "${{ values.gcpProject }}"
owner       = "${{ values.owner }}"

# -----------------------------------------------------------------------------
# Cluster Mode - Autopilot for dev (cost-optimized, fully managed)
# -----------------------------------------------------------------------------
cluster_mode = "autopilot"

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------
network_id          = "${{ values.networkId }}"
subnet_id           = "${{ values.subnetId }}"
pods_range_name     = "pods"
services_range_name = "services"

# -----------------------------------------------------------------------------
# Private Cluster - Disabled for easier dev access
# -----------------------------------------------------------------------------
enable_private_endpoint = false
master_ipv4_cidr_block  = "172.16.0.0/28"
master_authorized_networks = [
  {
    cidr_block   = "0.0.0.0/0"
    display_name = "All networks (dev only)"
  }
]

# -----------------------------------------------------------------------------
# Release Channel - Regular for dev (faster updates)
# -----------------------------------------------------------------------------
release_channel = "REGULAR"

# -----------------------------------------------------------------------------
# Security Configuration
# -----------------------------------------------------------------------------
enable_network_policy = false

# -----------------------------------------------------------------------------
# Cluster Autoscaling (Not used in Autopilot mode)
# -----------------------------------------------------------------------------
enable_cluster_autoscaling = false
autoscaling_cpu_min        = 1
autoscaling_cpu_max        = 20
autoscaling_memory_min     = 1
autoscaling_memory_max     = 40

# -----------------------------------------------------------------------------
# Node Pool Configuration (Not used in Autopilot mode, but defined for completeness)
# -----------------------------------------------------------------------------
node_count          = 1
node_pool_min_count = 1
node_pool_max_count = 3
machine_type        = "e2-medium"
disk_size_gb        = 50
disk_type           = "pd-standard"
image_type          = "COS_CONTAINERD"
use_preemptible_nodes = true
use_spot_nodes        = false

# -----------------------------------------------------------------------------
# Node Pool Upgrade
# -----------------------------------------------------------------------------
max_surge       = 1
max_unavailable = 0

# -----------------------------------------------------------------------------
# Node Taints
# -----------------------------------------------------------------------------
node_taints = []

# -----------------------------------------------------------------------------
# Additional Node Pools
# -----------------------------------------------------------------------------
additional_node_pools = {}

# -----------------------------------------------------------------------------
# Maintenance Window - Weekends only
# -----------------------------------------------------------------------------
maintenance_start_time = "2024-01-01T04:00:00Z"
maintenance_end_time   = "2024-01-01T08:00:00Z"
maintenance_recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"

# -----------------------------------------------------------------------------
# Artifact Registry
# -----------------------------------------------------------------------------
create_artifact_registry     = true
artifact_registry_keep_count = 5

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------
labels = {
  cost-center = "development"
  team        = "${{ values.owner }}"
}
