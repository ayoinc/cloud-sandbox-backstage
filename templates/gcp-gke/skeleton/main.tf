# =============================================================================
# GCP GKE - Root Configuration
# =============================================================================
# This is the main entry point that calls the GKE module.
# Environment-specific values are provided via tfvars files.
# =============================================================================

module "gke" {
  source = "./modules/gke"

  # Required variables
  name        = var.name
  environment = var.environment
  region      = var.region
  project_id  = var.project_id
  owner       = var.owner
  labels      = var.labels

  # Cluster mode
  cluster_mode = var.cluster_mode

  # Network configuration
  network_id          = var.network_id
  subnet_id           = var.subnet_id
  pods_range_name     = var.pods_range_name
  services_range_name = var.services_range_name

  # Private cluster configuration
  enable_private_endpoint    = var.enable_private_endpoint
  master_ipv4_cidr_block     = var.master_ipv4_cidr_block
  master_authorized_networks = var.master_authorized_networks

  # Release channel
  release_channel = var.release_channel

  # Security
  enable_network_policy = var.enable_network_policy

  # Cluster autoscaling
  enable_cluster_autoscaling = var.enable_cluster_autoscaling
  autoscaling_cpu_min        = var.autoscaling_cpu_min
  autoscaling_cpu_max        = var.autoscaling_cpu_max
  autoscaling_memory_min     = var.autoscaling_memory_min
  autoscaling_memory_max     = var.autoscaling_memory_max

  # Node pool configuration
  node_count            = var.node_count
  node_pool_min_count   = var.node_pool_min_count
  node_pool_max_count   = var.node_pool_max_count
  machine_type          = var.machine_type
  disk_size_gb          = var.disk_size_gb
  disk_type             = var.disk_type
  image_type            = var.image_type
  use_preemptible_nodes = var.use_preemptible_nodes
  use_spot_nodes        = var.use_spot_nodes

  # Node pool upgrade
  max_surge       = var.max_surge
  max_unavailable = var.max_unavailable

  # Node taints
  node_taints = var.node_taints

  # Additional node pools
  additional_node_pools = var.additional_node_pools

  # Maintenance window
  maintenance_start_time = var.maintenance_start_time
  maintenance_end_time   = var.maintenance_end_time
  maintenance_recurrence = var.maintenance_recurrence

  # Artifact Registry
  create_artifact_registry     = var.create_artifact_registry
  artifact_registry_keep_count = var.artifact_registry_keep_count
}
