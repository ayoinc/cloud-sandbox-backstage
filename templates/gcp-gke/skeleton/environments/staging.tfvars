# =============================================================================
# GCP GKE - Staging Environment Configuration
# =============================================================================
# This file contains Jinja2 template variables that will be substituted
# by Backstage when the template is scaffolded.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables (from Backstage template)
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "staging"
region      = "${{ values.region }}"
project_id  = "${{ values.gcpProject }}"
owner       = "${{ values.owner }}"

# -----------------------------------------------------------------------------
# Cluster Mode - Standard for staging (production-like)
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
# Private Cluster - Public endpoint for staging
# -----------------------------------------------------------------------------
enable_private_endpoint = false
master_ipv4_cidr_block  = "172.16.0.0/28"
master_authorized_networks = [
  {
    cidr_block   = "10.0.0.0/8"
    display_name = "Internal networks"
  }
]

# -----------------------------------------------------------------------------
# Release Channel - Regular for staging
# -----------------------------------------------------------------------------
release_channel = "REGULAR"

# -----------------------------------------------------------------------------
# Security Configuration
# -----------------------------------------------------------------------------
enable_network_policy = true

# -----------------------------------------------------------------------------
# Cluster Autoscaling (NAP)
# -----------------------------------------------------------------------------
enable_cluster_autoscaling = true
autoscaling_cpu_min        = 2
autoscaling_cpu_max        = 50
autoscaling_memory_min     = 4
autoscaling_memory_max     = 100

# -----------------------------------------------------------------------------
# Node Pool Configuration
# -----------------------------------------------------------------------------
node_count            = 2
node_pool_min_count   = 2
node_pool_max_count   = 6
machine_type          = "e2-standard-4"
disk_size_gb          = 100
disk_type             = "pd-balanced"
image_type            = "COS_CONTAINERD"
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
artifact_registry_keep_count = 10

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------
labels = {
  cost-center = "staging"
  team        = "${{ values.owner }}"
}
