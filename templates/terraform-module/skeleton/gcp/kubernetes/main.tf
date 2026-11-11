locals {
  # Resource names are limited to 63 characters and service account IDs to 30,
  # so the project name is shortened before the environment is appended.
  name_prefix = "${trimsuffix(substr(var.project_name, 0, 16), "-")}-${var.environment}"

  labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })

  # A null network selects the project's default network.
  network = coalesce(var.network_name, "default")

  node_service_account_member = "serviceAccount:${google_service_account.nodes.email}"
  node_oauth_scopes           = ["https://www.googleapis.com/auth/cloud-platform"]
}

# -----------------------------------------------------------------------------
# Node identity
# -----------------------------------------------------------------------------

resource "google_service_account" "nodes" {
  project      = var.project_id
  account_id   = "${local.name_prefix}-gke"
  display_name = "${var.project_name} ${var.environment} GKE nodes"
  description  = "Identity of the ${var.project_name} GKE nodes in ${var.environment}"
}

# The minimum a node needs to write logs and metrics and report to the control plane.
resource "google_project_iam_member" "nodes" {
  project = var.project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = local.node_service_account_member
}

# -----------------------------------------------------------------------------
# Cluster
# -----------------------------------------------------------------------------

# Autopilot always runs Shielded GKE Nodes and the provider rejects
# enable_shielded_nodes together with enable_autopilot, so the argument can
# only be set for Standard clusters, where it is true.
# trivy:ignore:AVD-GCP-0055
resource "google_container_cluster" "main" {
  project             = var.project_id
  name                = "${local.name_prefix}-gke"
  description         = "GKE cluster for ${var.project_name} (${var.environment})"
  location            = var.region
  network             = local.network
  subnetwork          = var.subnet_name
  deletion_protection = var.deletion_protection
  resource_labels     = local.labels

  enable_autopilot = var.enable_autopilot ? true : null

  # Standard clusters keep a small default pool for system workloads; workload
  # pools are separate resources so they can change without touching the cluster.
  initial_node_count = var.enable_autopilot ? null : var.system_node_count
  datapath_provider  = var.enable_autopilot ? null : "ADVANCED_DATAPATH"

  enable_legacy_abac    = false
  enable_shielded_nodes = var.enable_autopilot ? null : true

  release_channel {
    channel = var.release_channel
  }

  # Null range names let GKE create and manage the pod and service ranges.
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
    gcp_public_cidrs_access_enabled = false

    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks

      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  dynamic "database_encryption" {
    for_each = var.kms_key_id == null ? [] : [var.kms_key_id]

    content {
      state    = "ENCRYPTED"
      key_name = database_encryption.value
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_start_time
    }
  }

  # Autopilot provisions nodes itself; this makes them run as the dedicated
  # service account instead of the Compute Engine default one.
  dynamic "cluster_autoscaling" {
    for_each = var.enable_autopilot ? [1] : []

    content {
      auto_provisioning_defaults {
        service_account = google_service_account.nodes.email
        oauth_scopes    = local.node_oauth_scopes
      }
    }
  }

  dynamic "node_config" {
    for_each = var.enable_autopilot ? [] : [1]

    content {
      machine_type    = var.system_machine_type
      disk_size_gb    = 50
      disk_type       = "pd-balanced"
      image_type      = "COS_CONTAINERD"
      service_account = google_service_account.nodes.email
      oauth_scopes    = local.node_oauth_scopes
      resource_labels = local.labels

      labels = {
        pool = "system"
      }

      metadata = {
        disable-legacy-endpoints = "true"
      }

      shielded_instance_config {
        enable_secure_boot          = true
        enable_integrity_monitoring = true
      }

      workload_metadata_config {
        mode = "GKE_METADATA"
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.enable_private_endpoint || length(var.master_authorized_networks) > 0
      error_message = "A public control plane endpoint (enable_private_endpoint = false) requires at least one entry in master_authorized_networks."
    }

    precondition {
      condition     = !var.enable_autopilot || length(var.node_pools) == 0
      error_message = "node_pools only applies to Standard clusters. Set enable_autopilot = false or remove node_pools."
    }

    precondition {
      condition     = (var.pods_range_name == null) == (var.services_range_name == null)
      error_message = "pods_range_name and services_range_name must be set together or both left null."
    }
  }

  depends_on = [google_project_iam_member.nodes]
}

# -----------------------------------------------------------------------------
# Workload node pools (Standard clusters)
# -----------------------------------------------------------------------------

resource "google_container_node_pool" "main" {
  for_each = var.enable_autopilot ? {} : var.node_pools

  project  = var.project_id
  name     = each.key
  location = var.region
  cluster  = google_container_cluster.main.name

  initial_node_count = each.value.min_count

  autoscaling {
    min_node_count = each.value.min_count
    max_node_count = each.value.max_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  node_config {
    machine_type    = each.value.machine_type
    disk_size_gb    = each.value.disk_size_gb
    disk_type       = each.value.disk_type
    image_type      = "COS_CONTAINERD"
    spot            = each.value.spot
    service_account = google_service_account.nodes.email
    oauth_scopes    = local.node_oauth_scopes
    resource_labels = local.labels
    labels          = merge(each.value.labels, { pool = each.key })

    metadata = {
      disable-legacy-endpoints = "true"
    }

    dynamic "taint" {
      for_each = each.value.taints

      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  # The autoscaler owns the pool size after creation.
  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

# -----------------------------------------------------------------------------
# Container image repository
# -----------------------------------------------------------------------------

resource "google_artifact_registry_repository" "main" {
  count = var.enable_artifact_registry ? 1 : 0

  project       = var.project_id
  location      = var.region
  repository_id = "${local.name_prefix}-images"
  description   = "Container images for ${var.project_name} (${var.environment})"
  format        = "DOCKER"
  kms_key_name  = var.kms_key_id
  labels        = local.labels

  docker_config {
    immutable_tags = var.artifact_registry_immutable_tags
  }

  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"

    condition {
      tag_state  = "UNTAGGED"
      older_than = "${var.artifact_registry_untagged_retention_days}d"
    }
  }

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"

    most_recent_versions {
      keep_count = var.artifact_registry_keep_count
    }
  }
}

resource "google_artifact_registry_repository_iam_member" "nodes" {
  count = var.enable_artifact_registry ? 1 : 0

  project    = var.project_id
  location   = google_artifact_registry_repository.main[0].location
  repository = google_artifact_registry_repository.main[0].name
  role       = "roles/artifactregistry.reader"
  member     = local.node_service_account_member
}
