# -----------------------------------------------------------------------------
# GCP Kubernetes (GKE) Module - Main Resources
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_id}-${var.environment}"

  default_labels = {
    project     = var.project_id
    environment = var.environment
    managed_by  = "terraform"
  }

  labels = merge(local.default_labels, var.labels)

  # Workload identity pool format
  workload_identity_pool = var.enable_workload_identity ? "${var.project_id}.svc.id.goog" : null
}

# -----------------------------------------------------------------------------
# Service Account for GKE Nodes
# -----------------------------------------------------------------------------

resource "google_service_account" "gke_nodes" {
  account_id   = "${local.name_prefix}-gke-nodes-sa"
  display_name = "Service account for ${local.name_prefix} GKE nodes"
  project      = var.project_id
  description  = "Managed by Terraform - Service account for GKE cluster nodes"
}

# IAM Roles for Node Service Account
resource "google_project_iam_member" "gke_node_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader",
    "roles/storage.objectViewer",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# -----------------------------------------------------------------------------
# GKE Cluster
# -----------------------------------------------------------------------------

resource "google_container_cluster" "main" {
  name     = "${local.name_prefix}-gke"
  project  = var.project_id
  location = var.region

  description = "Managed by Terraform - GKE cluster for ${local.name_prefix}"

  # Remove default node pool - we'll create our own
  remove_default_node_pool = true
  initial_node_count       = 1

  # Kubernetes version and release channel
  min_master_version = var.cluster_version
  release_channel {
    channel = var.release_channel
  }

  # Network configuration
  network    = var.network_self_link
  subnetwork = var.subnetwork_self_link

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # Private cluster configuration
  dynamic "private_cluster_config" {
    for_each = var.enable_private_cluster ? [1] : []
    content {
      enable_private_nodes    = true
      enable_private_endpoint = var.enable_private_endpoint
      master_ipv4_cidr_block  = var.master_ipv4_cidr_block

      master_global_access_config {
        enabled = var.enable_master_global_access
      }
    }
  }

  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Network policy
  network_policy {
    enabled  = var.enable_network_policy
    provider = var.enable_network_policy ? "CALICO" : "PROVIDER_UNSPECIFIED"
  }

  # Workload Identity
  dynamic "workload_identity_config" {
    for_each = var.enable_workload_identity ? [1] : []
    content {
      workload_pool = local.workload_identity_pool
    }
  }

  # Logging and Monitoring
  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service

  # Logging config
  logging_config {
    enable_components = var.logging_components
  }

  # Monitoring config
  monitoring_config {
    enable_components = var.monitoring_components

    managed_prometheus {
      enabled = var.enable_managed_prometheus
    }
  }

  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = !var.enable_http_load_balancing
    }

    horizontal_pod_autoscaling {
      disabled = !var.enable_horizontal_pod_autoscaling
    }

    gce_persistent_disk_csi_driver_config {
      enabled = var.enable_gce_persistent_disk_csi_driver
    }

    gcp_filestore_csi_driver_config {
      enabled = var.enable_filestore_csi_driver
    }

    gcs_fuse_csi_driver_config {
      enabled = var.enable_gcs_fuse_csi_driver
    }

    network_policy_config {
      disabled = !var.enable_network_policy
    }

    dns_cache_config {
      enabled = var.enable_dns_cache
    }
  }

  # Cluster autoscaling (for node auto-provisioning)
  dynamic "cluster_autoscaling" {
    for_each = var.enable_node_auto_provisioning ? [1] : []
    content {
      enabled = true

      resource_limits {
        resource_type = "cpu"
        minimum       = var.node_auto_provisioning_cpu_min
        maximum       = var.node_auto_provisioning_cpu_max
      }

      resource_limits {
        resource_type = "memory"
        minimum       = var.node_auto_provisioning_memory_min
        maximum       = var.node_auto_provisioning_memory_max
      }

      auto_provisioning_defaults {
        service_account = google_service_account.gke_nodes.email
        oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

        management {
          auto_repair  = true
          auto_upgrade = true
        }

        disk_size = var.node_auto_provisioning_disk_size
        disk_type = var.node_auto_provisioning_disk_type
      }
    }
  }

  # Maintenance policy
  dynamic "maintenance_policy" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      daily_maintenance_window {
        start_time = maintenance_policy.value.start_time
      }
    }
  }

  # Binary authorization
  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  # Security posture
  security_posture_config {
    mode               = var.security_posture_mode
    vulnerability_mode = var.vulnerability_mode
  }

  # Datapath provider (for Dataplane V2)
  datapath_provider = var.datapath_provider

  # Vertical Pod Autoscaling
  vertical_pod_autoscaling {
    enabled = var.enable_vertical_pod_autoscaling
  }

  # Default SNAT status
  default_snat_status {
    disabled = var.disable_default_snat
  }

  # DNS config
  dns_config {
    cluster_dns        = var.cluster_dns
    cluster_dns_scope  = var.cluster_dns_scope
    cluster_dns_domain = var.cluster_dns_domain
  }

  # Deletion protection
  deletion_protection = var.deletion_protection

  resource_labels = local.labels

  lifecycle {
    ignore_changes = [
      node_pool,
      initial_node_count,
    ]
  }

  depends_on = [
    google_project_iam_member.gke_node_roles
  ]
}

# -----------------------------------------------------------------------------
# GKE Node Pools
# -----------------------------------------------------------------------------

resource "google_container_node_pool" "pools" {
  for_each = { for pool in var.node_pools : pool.name => pool }

  name     = each.value.name
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.main.name

  # Node count configuration
  initial_node_count = each.value.initial_node_count

  # Autoscaling configuration
  dynamic "autoscaling" {
    for_each = each.value.enable_autoscaling ? [1] : []
    content {
      min_node_count       = each.value.min_count
      max_node_count       = each.value.max_count
      location_policy      = each.value.location_policy
      total_min_node_count = each.value.total_min_count
      total_max_node_count = each.value.total_max_count
    }
  }

  # Node management
  management {
    auto_repair  = each.value.auto_repair
    auto_upgrade = each.value.auto_upgrade
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = each.value.max_surge
    max_unavailable = each.value.max_unavailable
    strategy        = each.value.upgrade_strategy

    dynamic "blue_green_settings" {
      for_each = each.value.upgrade_strategy == "BLUE_GREEN" ? [1] : []
      content {
        node_pool_soak_duration = each.value.node_pool_soak_duration

        standard_rollout_policy {
          batch_percentage    = each.value.batch_percentage
          batch_node_count    = each.value.batch_node_count
          batch_soak_duration = each.value.batch_soak_duration
        }
      }
    }
  }

  # Node configuration
  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type
    image_type   = each.value.image_type

    # Preemptible or Spot
    preemptible = each.value.preemptible
    spot        = each.value.spot

    # OAuth scopes
    oauth_scopes = each.value.oauth_scopes

    # Service account
    service_account = google_service_account.gke_nodes.email

    # Labels
    labels = merge(local.labels, each.value.labels, {
      node_pool = each.value.name
    })

    # Kubernetes labels
    resource_labels = merge(local.labels, {
      node_pool = each.value.name
    })

    # Tags for firewall rules
    tags = each.value.tags

    # Taints
    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    # Metadata
    metadata = merge({
      disable-legacy-endpoints = "true"
    }, each.value.metadata)

    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = each.value.enable_secure_boot
      enable_integrity_monitoring = each.value.enable_integrity_monitoring
    }

    # Workload metadata config
    dynamic "workload_metadata_config" {
      for_each = var.enable_workload_identity ? [1] : []
      content {
        mode = "GKE_METADATA"
      }
    }

    # Guest accelerators (GPUs)
    dynamic "guest_accelerator" {
      for_each = each.value.accelerator_count > 0 ? [1] : []
      content {
        type  = each.value.accelerator_type
        count = each.value.accelerator_count

        gpu_driver_installation_config {
          gpu_driver_version = each.value.gpu_driver_version
        }
      }
    }

    # Linux node config
    dynamic "linux_node_config" {
      for_each = length(each.value.sysctls) > 0 ? [1] : []
      content {
        sysctls = each.value.sysctls
      }
    }

    # Gcfs config (image streaming)
    gcfs_config {
      enabled = each.value.enable_gcfs
    }

    # Gvnic (Google Virtual NIC)
    gvnic {
      enabled = each.value.enable_gvnic
    }
  }

  # Node locations (zones)
  node_locations = each.value.node_locations

  # Network config
  network_config {
    enable_private_nodes = var.enable_private_cluster
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }
}

# -----------------------------------------------------------------------------
# Container Registry (Optional - Legacy)
# -----------------------------------------------------------------------------

resource "google_container_registry" "main" {
  count = var.enable_container_registry ? 1 : 0

  project  = var.project_id
  location = var.container_registry_location
}

# Grant GKE nodes access to Container Registry
resource "google_storage_bucket_iam_member" "gcr_viewer" {
  count = var.enable_container_registry ? 1 : 0

  bucket = google_container_registry.main[0].id
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# -----------------------------------------------------------------------------
# Artifact Registry Repository (Optional - Recommended)
# -----------------------------------------------------------------------------

resource "google_artifact_registry_repository" "main" {
  count = var.enable_artifact_registry ? 1 : 0

  project       = var.project_id
  location      = var.region
  repository_id = "${local.name_prefix}-docker"
  description   = "Docker repository for ${local.name_prefix} GKE cluster"
  format        = "DOCKER"

  cleanup_policy_dry_run = var.artifact_registry_cleanup_dry_run

  dynamic "cleanup_policies" {
    for_each = var.artifact_registry_cleanup_policies
    content {
      id     = cleanup_policies.value.id
      action = cleanup_policies.value.action

      dynamic "condition" {
        for_each = cleanup_policies.value.condition != null ? [cleanup_policies.value.condition] : []
        content {
          tag_state             = condition.value.tag_state
          tag_prefixes          = condition.value.tag_prefixes
          version_name_prefixes = condition.value.version_name_prefixes
          package_name_prefixes = condition.value.package_name_prefixes
          older_than            = condition.value.older_than
          newer_than            = condition.value.newer_than
        }
      }

      dynamic "most_recent_versions" {
        for_each = cleanup_policies.value.most_recent_versions != null ? [cleanup_policies.value.most_recent_versions] : []
        content {
          package_name_prefixes = most_recent_versions.value.package_name_prefixes
          keep_count            = most_recent_versions.value.keep_count
        }
      }
    }
  }

  labels = local.labels
}

# Grant GKE nodes access to Artifact Registry
resource "google_artifact_registry_repository_iam_member" "gke_reader" {
  count = var.enable_artifact_registry ? 1 : 0

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.main[0].name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.gke_nodes.email}"
}
