locals {
  # E2 custom machine types match the requested vCPU and memory exactly.
  node_machine_types = {
    small  = "e2-custom-2-4096"
    medium = "e2-custom-4-8192"
    large  = "e2-custom-8-16384"
    xlarge = "e2-custom-16-32768"
  }

  # Spot nodes cost far less but can be reclaimed at any time.
  spot_nodes = var.enable_cost_optimization && !local.is_production

  # The cluster is regional. Nodes are spread over up to three zones, fewer
  # when the cluster is smaller than that.
  node_zone_count = min(3, var.enable_autoscaling ? var.max_nodes : var.min_nodes)
  nodes_per_zone  = ceil(var.min_nodes / local.node_zone_count)
  available_zones = var.enable_kubernetes ? sort(data.google_compute_zones.available[0].names) : []

  # The network range may always reach the API; so may the listed clients.
  kubernetes_api_cidrs = merge(
    var.enable_networking ? { network = var.network_cidr } : {},
    { for index, cidr in var.kubernetes_api_allowed_cidrs : "allowed-${index + 1}" => cidr },
  )
}

data "google_compute_zones" "available" {
  count = var.enable_kubernetes ? 1 : 0

  project = terraform_data.api_ready["compute.googleapis.com"].output
  region  = var.region
  status  = "UP"
}

resource "google_service_account" "gke_nodes" {
  count = var.enable_kubernetes ? 1 : 0

  project      = var.project_id
  account_id   = "${var.name_prefix}-gke"
  display_name = "GKE nodes of ${var.name_prefix}"

  depends_on = [time_sleep.api_propagation]
}

# The minimum a node needs: write logs and metrics, read cluster metadata.
resource "google_project_iam_member" "gke_nodes" {
  count = var.enable_kubernetes ? 1 : 0

  project = var.project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_container_cluster" "this" {
  count = var.enable_kubernetes ? 1 : 0

  project     = var.project_id
  name        = "${var.name_prefix}-gke"
  description = "Kubernetes cluster of the ${var.name_prefix} ${var.environment} stack"
  location    = var.region

  node_locations = slice(local.available_zones, 0, min(local.node_zone_count, length(local.available_zones)))

  network         = local.network_id
  subnetwork      = try(local.private_subnet_ids[0], null)
  networking_mode = "VPC_NATIVE"

  # Dataplane V2 enforces Kubernetes network policies.
  datapath_provider = "ADVANCED_DATAPATH"

  min_master_version  = var.kubernetes_version
  deletion_protection = var.require_deletion_protection

  enable_shielded_nodes = true
  enable_legacy_abac    = false
  resource_labels       = local.labels

  release_channel {
    channel = "REGULAR"
  }

  # GKE picks free ranges of these sizes for pods and services and adds them
  # to the subnet.
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = length(var.kubernetes_api_allowed_cidrs) == 0
    master_ipv4_cidr_block  = var.kubernetes_control_plane_cidr
  }

  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = false

    dynamic "cidr_blocks" {
      for_each = local.kubernetes_api_cidrs

      content {
        cidr_block   = cidr_blocks.value
        display_name = cidr_blocks.key
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

  # Kubernetes secrets are encrypted with the customer-managed key.
  dynamic "database_encryption" {
    for_each = var.enable_kms ? [1] : []

    content {
      state    = "ENCRYPTED"
      key_name = local.kms_key_id
    }
  }

  # Pods can mount secrets from Secret Manager.
  dynamic "secret_manager_config" {
    for_each = var.enable_secrets_manager ? [1] : []

    content {
      enabled = true
    }
  }

  logging_config {
    enable_components = concat(
      ["SYSTEM_COMPONENTS", "WORKLOADS"],
      var.enable_monitoring ? ["APISERVER", "SCHEDULER", "CONTROLLER_MANAGER"] : [],
    )
  }

  monitoring_config {
    enable_components = concat(
      ["SYSTEM_COMPONENTS"],
      var.enable_monitoring ? ["APISERVER", "SCHEDULER", "CONTROLLER_MANAGER"] : [],
      var.enable_managed_prometheus ? ["STORAGE", "POD", "DEPLOYMENT", "STATEFULSET", "DAEMONSET", "HPA"] : [],
    )

    managed_prometheus {
      enabled = var.enable_managed_prometheus
    }
  }

  # Cost of the cluster broken down by namespace and label in billing data.
  cost_management_config {
    enabled = var.enable_cost_optimization
  }

  addons_config {
    gke_backup_agent_config {
      enabled = var.enable_backup
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "02:00"
    }
  }

  node_pool {
    name = "primary"

    # With autoscaling the pool starts at this size per zone and then follows
    # the cluster-wide bounds; without, it keeps this size per zone.
    initial_node_count = var.enable_autoscaling ? local.nodes_per_zone : null
    node_count         = var.enable_autoscaling ? null : local.nodes_per_zone

    dynamic "autoscaling" {
      for_each = var.enable_autoscaling ? [1] : []

      content {
        total_min_node_count = var.min_nodes
        total_max_node_count = var.max_nodes
        location_policy      = local.spot_nodes ? "ANY" : "BALANCED"
      }
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
      machine_type      = local.node_machine_types[var.node_size]
      image_type        = "COS_CONTAINERD"
      disk_type         = "pd-balanced"
      disk_size_gb      = 100
      spot              = local.spot_nodes
      service_account   = google_service_account.gke_nodes[0].email
      oauth_scopes      = ["https://www.googleapis.com/auth/cloud-platform"]
      tags              = [local.gke_node_tag]
      resource_labels   = local.labels
      boot_disk_kms_key = local.kms_key_id

      metadata = {
        disable-legacy-endpoints = "true"
      }

      # Pods get credentials through Workload Identity, not from the node.
      workload_metadata_config {
        mode = "GKE_METADATA"
      }

      shielded_instance_config {
        enable_secure_boot          = true
        enable_integrity_monitoring = true
      }
    }
  }

  # Nodes without external addresses pull images through Cloud NAT.
  depends_on = [
    time_sleep.api_propagation,
    time_sleep.kms_iam_propagation,
    google_compute_router_nat.this,
    google_project_iam_member.gke_nodes,
  ]

  lifecycle {
    precondition {
      condition     = local.network_available
      error_message = local.network_required_message
    }

    precondition {
      condition     = !local.network_available || length(local.private_subnet_ids) > 0
      error_message = "The cluster runs in a private subnet: existing_network.private_subnet_ids must not be empty."
    }
  }
}
