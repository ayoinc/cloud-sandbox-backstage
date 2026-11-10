# =============================================================================
# Containers: GKE cluster, node pool and Artifact Registry
# =============================================================================

locals {
  gke_subnet_cidr = coalesce(
    var.gke_subnet_cidr,
    cidrsubnet(var.network_cidr, 20 - tonumber(split("/", var.network_cidr)[1]), pow(2, 20 - tonumber(split("/", var.network_cidr)[1])) - 1)
  )

  gke_subnetwork_id = format(
    "projects/%s/regions/%s/subnetworks/%s",
    var.project_id,
    var.region,
    var.enable_networking && var.enable_containers ? google_compute_subnetwork.gke[0].name : var.existing_subnetwork
  )
}

resource "google_compute_subnetwork" "gke" {
  count = var.enable_networking && var.enable_containers ? 1 : 0

  name                     = "${local.name_prefix}-gke"
  network                  = google_compute_network.main[0].id
  region                   = var.region
  ip_cidr_range            = local.gke_subnet_cidr
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_service_account" "gke_nodes" {
  count = var.enable_containers ? 1 : 0

  account_id   = "${local.sa_prefix}-gke"
  display_name = "GKE nodes of ${local.name_prefix}"

  depends_on = [google_project_service.main]
}

resource "google_project_iam_member" "gke_nodes" {
  for_each = var.enable_containers ? toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader",
  ]) : toset([])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_container_cluster" "main" {
  # checkov:skip=CKV_GCP_21:Labels come from local.labels, which is built from variables that a static scan cannot resolve
  # checkov:skip=CKV_GCP_65:Google Groups for RBAC needs a Google Workspace group; set gke_rbac_security_group to enable it
  # checkov:skip=CKV_GCP_69:The default node pool is removed; the node pool below sets workload_metadata_config to GKE_METADATA
  count = var.enable_containers ? 1 : 0

  name               = "${local.name_prefix}-gke"
  description        = "GKE cluster of ${var.project_name} (${var.environment})"
  location           = var.region
  min_master_version = var.gke_version

  # The node pool is managed separately.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = local.network_id
  subnetwork = local.gke_subnetwork_id

  # GKE creates the secondary ranges for pods and services on the subnet.
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.gke_pods_cidr
    services_ipv4_cidr_block = var.gke_services_cidr
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.gke_master_cidr
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.network_cidr
      display_name = "vpc"
    }

    dynamic "cidr_blocks" {
      for_each = var.gke_master_authorized_networks
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

  dynamic "authenticator_groups_config" {
    for_each = var.gke_rbac_security_group == null ? [] : [var.gke_rbac_security_group]
    content {
      security_group = authenticator_groups_config.value
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  addons_config {
    network_policy_config {
      disabled = false
    }
  }

  enable_intranode_visibility = true
  enable_shielded_nodes       = true

  resource_labels     = local.labels
  deletion_protection = local.is_production

  depends_on = [google_project_service.main]
}

resource "google_container_node_pool" "main" {
  count = var.enable_containers ? 1 : 0

  name               = "primary"
  location           = var.region
  cluster            = google_container_cluster.main[0].name
  node_locations     = length(var.gke_node_locations) > 0 ? var.gke_node_locations : null
  initial_node_count = var.gke_initial_node_count

  autoscaling {
    min_node_count = var.gke_min_node_count
    max_node_count = var.gke_max_node_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = var.gke_node_machine_type
    image_type      = "COS_CONTAINERD"
    service_account = google_service_account.gke_nodes[0].email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    labels          = local.labels

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  # The autoscaler changes the node count after creation.
  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

resource "google_artifact_registry_repository" "main" {
  # checkov:skip=CKV_GCP_84:Google-managed encryption is used; a customer-managed key needs a grant to the Artifact Registry service agent first
  count = var.enable_containers ? 1 : 0

  location      = var.region
  repository_id = local.name_prefix
  description   = "Container images of ${var.project_name} (${var.environment})"
  format        = "DOCKER"
  labels        = local.labels

  depends_on = [google_project_service.main]
}
