# =============================================================================
# GCP GKE MODULE
# =============================================================================
# Creates GKE cluster with node pools and workload identity
# Follows Google Cloud best practices for Kubernetes
# Provider version: ~> 5.0
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zones" {
  description = "Zones for the cluster (leave empty for regional)"
  type        = list(string)
  default     = []
}

variable "network" {
  description = "VPC network name or self_link"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork name or self_link"
  type        = string
}

variable "pods_range_name" {
  description = "Secondary range name for pods"
  type        = string
  default     = null
}

variable "services_range_name" {
  description = "Secondary range name for services"
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = null
}

variable "release_channel" {
  description = "Release channel (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "enable_private_nodes" {
  description = "Enable private nodes"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for master nodes"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = "CIDR blocks allowed to access the master"
  type = list(object({
    display_name = string
    cidr_block   = string
  }))
  default = []
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable network policy"
  type        = bool
  default     = true
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization"
  type        = bool
  default     = false
}

variable "enable_shielded_nodes" {
  description = "Enable shielded nodes"
  type        = bool
  default     = true
}

variable "node_pools" {
  description = "Node pool configurations"
  type = map(object({
    machine_type       = string
    disk_size_gb       = optional(number, 100)
    disk_type          = optional(string, "pd-standard")
    image_type         = optional(string, "COS_CONTAINERD")
    initial_node_count = optional(number, 1)
    min_count          = number
    max_count          = number
    preemptible        = optional(bool, false)
    spot               = optional(bool, false)
    labels             = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {
    default = {
      machine_type = "e2-medium"
      min_count    = 1
      max_count    = 3
    }
  }
}

variable "maintenance_start_time" {
  description = "Maintenance window start time (UTC)"
  type        = string
  default     = "03:00"
}

variable "maintenance_recurrence" {
  description = "Maintenance window recurrence"
  type        = string
  default     = "FREQ=WEEKLY;BYDAY=SA,SU"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "google_container_engine_versions" "main" {
  project        = var.project_id
  location       = var.region
  version_prefix = var.kubernetes_version
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  cluster_name = "${var.name}-${var.environment}-gke"

  common_labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })

  # Determine if regional or zonal
  location = length(var.zones) > 0 ? var.zones[0] : var.region
}

# -----------------------------------------------------------------------------
# GKE Cluster
# -----------------------------------------------------------------------------

resource "google_container_cluster" "main" {
  project  = var.project_id
  name     = local.cluster_name
  location = local.location

  # Use release channel or specific version
  release_channel {
    channel = var.release_channel
  }

  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  # Network configuration
  network    = var.network
  subnetwork = var.subnetwork

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          display_name = cidr_blocks.value.display_name
          cidr_block   = cidr_blocks.value.cidr_block
        }
      }
    }
  }

  # Workload Identity
  dynamic "workload_identity_config" {
    for_each = var.enable_workload_identity ? [1] : []
    content {
      workload_pool = "${var.project_id}.svc.id.goog"
    }
  }

  # Network policy
  network_policy {
    enabled  = var.enable_network_policy
    provider = var.enable_network_policy ? "CALICO" : "PROVIDER_UNSPECIFIED"
  }

  # Binary Authorization
  binary_authorization {
    evaluation_mode = var.enable_binary_authorization ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  }

  # Maintenance window
  maintenance_policy {
    recurring_window {
      start_time = "2024-01-01T${var.maintenance_start_time}:00Z"
      end_time   = "2024-01-01T07:00:00Z"
      recurrence = var.maintenance_recurrence
    }
  }

  # Cluster addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
      disabled = !var.enable_network_policy
    }
    gcs_fuse_csi_driver_config {
      enabled = true
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # Logging and monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  # Security
  enable_shielded_nodes = var.enable_shielded_nodes

  resource_labels = local.common_labels
}

# -----------------------------------------------------------------------------
# Node Pools
# -----------------------------------------------------------------------------

resource "google_container_node_pool" "pools" {
  for_each = var.node_pools

  project  = var.project_id
  name     = "${local.cluster_name}-${each.key}"
  location = local.location
  cluster  = google_container_cluster.main.name

  initial_node_count = each.value.initial_node_count

  autoscaling {
    min_node_count = each.value.min_count
    max_node_count = each.value.max_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type
    image_type   = each.value.image_type

    preemptible = each.value.preemptible
    spot        = each.value.spot

    labels = merge(each.value.labels, {
      environment = var.environment
      node_pool   = each.key
    })

    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    # Service account
    service_account = "default"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Security
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Workload Identity
    dynamic "workload_metadata_config" {
      for_each = var.enable_workload_identity ? [1] : []
      content {
        mode = "GKE_METADATA"
      }
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "cluster_id" {
  description = "GKE cluster ID"
  value       = google_container_cluster.main.id
}

output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.main.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.main.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.main.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "GKE cluster location"
  value       = google_container_cluster.main.location
}

output "cluster_master_version" {
  description = "GKE master version"
  value       = google_container_cluster.main.master_version
}

output "node_pools" {
  description = "Node pool names"
  value       = [for np in google_container_node_pool.pools : np.name]
}
