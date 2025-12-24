# =============================================================================
# GCP GKE Module - Main Configuration
# =============================================================================
# Creates a Google Kubernetes Engine cluster with:
# - Support for Autopilot and Standard modes
# - Node pools with autoscaling
# - Workload Identity
# - Private cluster configuration
# - Artifact Registry for container images
# =============================================================================

locals {
  # Naming convention: {name}-{environment}
  cluster_name = "${var.name}-${var.environment}"
  sa_name      = "${var.name}-${var.environment}-gke"

  # Common labels for all resources
  common_labels = merge(
    {
      project      = var.name
      environment  = var.environment
      managed-by   = "terraform"
      owner        = replace(var.owner, "/", "-")
      cluster-mode = var.cluster_mode
    },
    var.labels
  )

  # Determine if this is production (for security settings)
  is_production = contains(["prod", "production"], var.environment)
}

# =============================================================================
# Service Account for GKE Nodes
# =============================================================================
resource "google_service_account" "gke_nodes" {
  account_id   = local.sa_name
  display_name = "GKE Node Service Account for ${var.name}"
  description  = "Service account for GKE nodes in ${var.name} cluster"
}

# IAM bindings for node service account
resource "google_project_iam_member" "gke_nodes" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# =============================================================================
# Artifact Registry
# =============================================================================
resource "google_artifact_registry_repository" "main" {
  count = var.create_artifact_registry ? 1 : 0

  location      = var.region
  repository_id = "${var.name}-${var.environment}"
  description   = "Container registry for ${var.name}"
  format        = "DOCKER"

  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = var.artifact_registry_keep_count
    }
  }

  labels = local.common_labels
}

# =============================================================================
# GKE Cluster - Autopilot Mode
# =============================================================================
resource "google_container_cluster" "autopilot" {
  count    = var.cluster_mode == "autopilot" ? 1 : 0
  name     = local.cluster_name
  location = var.region

  enable_autopilot = true

  network    = var.network_id
  subnetwork = var.subnet_id

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  release_channel {
    channel = var.release_channel
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Security settings
  binary_authorization {
    evaluation_mode = local.is_production ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  }

  # Network policy
  network_policy {
    enabled  = var.enable_network_policy
    provider = var.enable_network_policy ? "CALICO" : "PROVIDER_UNSPECIFIED"
  }

  # Maintenance window
  maintenance_policy {
    recurring_window {
      start_time = var.maintenance_start_time
      end_time   = var.maintenance_end_time
      recurrence = var.maintenance_recurrence
    }
  }

  resource_labels = local.common_labels

  deletion_protection = local.is_production
}

# =============================================================================
# GKE Cluster - Standard Mode
# =============================================================================
resource "google_container_cluster" "standard" {
  count    = var.cluster_mode == "standard" ? 1 : 0
  name     = local.cluster_name
  location = var.region

  # We'll manage node pools separately
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_id
  subnetwork = var.subnet_id

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  release_channel {
    channel = var.release_channel
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Cluster autoscaling for resource limits
  cluster_autoscaling {
    enabled = var.enable_cluster_autoscaling
    dynamic "resource_limits" {
      for_each = var.enable_cluster_autoscaling ? [1] : []
      content {
        resource_type = "cpu"
        minimum       = var.autoscaling_cpu_min
        maximum       = var.autoscaling_cpu_max
      }
    }
    dynamic "resource_limits" {
      for_each = var.enable_cluster_autoscaling ? [1] : []
      content {
        resource_type = "memory"
        minimum       = var.autoscaling_memory_min
        maximum       = var.autoscaling_memory_max
      }
    }
  }

  # Security settings
  binary_authorization {
    evaluation_mode = local.is_production ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  }

  # Network policy
  network_policy {
    enabled  = var.enable_network_policy
    provider = var.enable_network_policy ? "CALICO" : "PROVIDER_UNSPECIFIED"
  }

  # Maintenance window
  maintenance_policy {
    recurring_window {
      start_time = var.maintenance_start_time
      end_time   = var.maintenance_end_time
      recurrence = var.maintenance_recurrence
    }
  }

  resource_labels = local.common_labels

  deletion_protection = local.is_production
}

# =============================================================================
# Primary Node Pool (Standard Mode Only)
# =============================================================================
resource "google_container_node_pool" "primary" {
  count      = var.cluster_mode == "standard" ? 1 : 0
  name       = "primary"
  location   = var.region
  cluster    = google_container_cluster.standard[0].name
  node_count = var.node_count

  autoscaling {
    min_node_count = var.node_pool_min_count
    max_node_count = var.node_pool_max_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = var.max_surge
    max_unavailable = var.max_unavailable
  }

  node_config {
    preemptible  = var.use_preemptible_nodes
    spot         = var.use_spot_nodes
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    image_type   = var.image_type

    service_account = google_service_account.gke_nodes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    labels = local.common_labels

    dynamic "taint" {
      for_each = var.node_taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }
}

# =============================================================================
# Additional Node Pool (Optional, Standard Mode Only)
# =============================================================================
resource "google_container_node_pool" "additional" {
  for_each   = var.cluster_mode == "standard" ? var.additional_node_pools : {}
  name       = each.key
  location   = var.region
  cluster    = google_container_cluster.standard[0].name
  node_count = each.value.node_count

  autoscaling {
    min_node_count = each.value.min_count
    max_node_count = each.value.max_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = each.value.preemptible
    spot         = each.value.spot
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type

    service_account = google_service_account.gke_nodes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    labels = merge(local.common_labels, each.value.labels)

    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }
}
