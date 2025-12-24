# =============================================================================
# GCP GKE - Root Variables
# =============================================================================
# These variables are passed to the GKE module.
# No Jinja2 defaults - values come from environments/*.tfvars
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the GKE cluster (used in resource naming)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "GCP region for the GKE cluster"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

# -----------------------------------------------------------------------------
# Optional Metadata
# -----------------------------------------------------------------------------

variable "owner" {
  description = "Owner of the GKE resources"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Cluster Mode Configuration
# -----------------------------------------------------------------------------

variable "cluster_mode" {
  description = "Cluster mode: autopilot (fully managed) or standard (self-managed node pools)"
  type        = string
  default     = "autopilot"
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "network_id" {
  description = "VPC Network ID or self_link for the GKE cluster"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID or self_link for the GKE cluster"
  type        = string
}

variable "pods_range_name" {
  description = "Name of the secondary IP range for pods"
  type        = string
  default     = "pods"
}

variable "services_range_name" {
  description = "Name of the secondary IP range for services"
  type        = string
  default     = "services"
}

# -----------------------------------------------------------------------------
# Private Cluster Configuration
# -----------------------------------------------------------------------------

variable "enable_private_endpoint" {
  description = "Enable private endpoint (master only accessible from within VPC)"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the GKE master network"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = "List of authorized networks that can access the master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Release Channel Configuration
# -----------------------------------------------------------------------------

variable "release_channel" {
  description = "Release channel for GKE version updates"
  type        = string
  default     = "REGULAR"
}

# -----------------------------------------------------------------------------
# Security Configuration
# -----------------------------------------------------------------------------

variable "enable_network_policy" {
  description = "Enable Kubernetes network policies (Calico)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Cluster Autoscaling (Standard Mode)
# -----------------------------------------------------------------------------

variable "enable_cluster_autoscaling" {
  description = "Enable cluster-level autoscaling (NAP - Node Auto-Provisioning)"
  type        = bool
  default     = false
}

variable "autoscaling_cpu_min" {
  description = "Minimum CPU cores for cluster autoscaling"
  type        = number
  default     = 1
}

variable "autoscaling_cpu_max" {
  description = "Maximum CPU cores for cluster autoscaling"
  type        = number
  default     = 100
}

variable "autoscaling_memory_min" {
  description = "Minimum memory (GB) for cluster autoscaling"
  type        = number
  default     = 1
}

variable "autoscaling_memory_max" {
  description = "Maximum memory (GB) for cluster autoscaling"
  type        = number
  default     = 1000
}

# -----------------------------------------------------------------------------
# Primary Node Pool Configuration (Standard Mode Only)
# -----------------------------------------------------------------------------

variable "node_count" {
  description = "Initial number of nodes in the primary node pool"
  type        = number
  default     = 3
}

variable "node_pool_min_count" {
  description = "Minimum number of nodes in the primary node pool"
  type        = number
  default     = 1
}

variable "node_pool_max_count" {
  description = "Maximum number of nodes in the primary node pool"
  type        = number
  default     = 10
}

variable "machine_type" {
  description = "Machine type for nodes in the primary node pool"
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB for nodes"
  type        = number
  default     = 100
}

variable "disk_type" {
  description = "Boot disk type for nodes"
  type        = string
  default     = "pd-standard"
}

variable "image_type" {
  description = "Node image type"
  type        = string
  default     = "COS_CONTAINERD"
}

variable "use_preemptible_nodes" {
  description = "Use preemptible VMs for nodes (cost-effective, may be terminated)"
  type        = bool
  default     = false
}

variable "use_spot_nodes" {
  description = "Use Spot VMs for nodes (cost-effective, may be terminated)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Node Pool Upgrade Configuration
# -----------------------------------------------------------------------------

variable "max_surge" {
  description = "Max number of nodes created during upgrade"
  type        = number
  default     = 1
}

variable "max_unavailable" {
  description = "Max number of nodes that can be unavailable during upgrade"
  type        = number
  default     = 0
}

# -----------------------------------------------------------------------------
# Node Taints and Labels
# -----------------------------------------------------------------------------

variable "node_taints" {
  description = "List of taints to apply to nodes in the primary pool"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Additional Node Pools (Standard Mode Only)
# -----------------------------------------------------------------------------

variable "additional_node_pools" {
  description = "Map of additional node pools to create"
  type = map(object({
    node_count   = number
    min_count    = number
    max_count    = number
    machine_type = string
    disk_size_gb = number
    disk_type    = string
    preemptible  = bool
    spot         = bool
    labels       = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Maintenance Window Configuration
# -----------------------------------------------------------------------------

variable "maintenance_start_time" {
  description = "Start time for maintenance window (RFC3339 format)"
  type        = string
  default     = "2024-01-01T04:00:00Z"
}

variable "maintenance_end_time" {
  description = "End time for maintenance window (RFC3339 format)"
  type        = string
  default     = "2024-01-01T08:00:00Z"
}

variable "maintenance_recurrence" {
  description = "Maintenance window recurrence (RRULE format)"
  type        = string
  default     = "FREQ=WEEKLY;BYDAY=SA,SU"
}

# -----------------------------------------------------------------------------
# Artifact Registry Configuration
# -----------------------------------------------------------------------------

variable "create_artifact_registry" {
  description = "Create an Artifact Registry for container images"
  type        = bool
  default     = true
}

variable "artifact_registry_keep_count" {
  description = "Number of container image versions to keep in Artifact Registry"
  type        = number
  default     = 10
}
