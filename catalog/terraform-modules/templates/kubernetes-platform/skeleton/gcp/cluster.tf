# -----------------------------------------------------------------------------
# Control plane
# -----------------------------------------------------------------------------

resource "google_container_cluster" "this" {
  project  = var.gcp_project_id
  name     = local.cluster_name
  location = var.region

  # GKE resolves a minor version to its newest patch release. Later upgrades follow the release channel.
  min_master_version = var.kubernetes_version

  dynamic "release_channel" {
    for_each = var.release_channel == null ? [] : [var.release_channel]

    content {
      channel = release_channel.value
    }
  }

  # The nodes are in the node pool below. GKE versions before 1.36.4 cannot create a cluster without a default
  # node pool, so one is created with a single node per zone and removed again.
  remove_default_node_pool = true
  initial_node_count       = 1

  network         = module.vpc.network_self_link
  subnetwork      = module.vpc.subnet_self_links["gke"]
  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = local.pods_range_name
    services_secondary_range_name = local.services_range_name
  }

  # GKE Dataplane V2 enforces NetworkPolicy objects. Without network policies the cluster uses kube-proxy, which
  # ignores them. The data plane of a cluster cannot be changed after it is created.
  datapath_provider = var.enable_network_policies ? "ADVANCED_DATAPATH" : "LEGACY_DATAPATH"

  # Nodes have internal addresses only, and the IP-based endpoint of the control plane is reachable only from
  # inside the network.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # No address outside the network is authorized for the IP-based endpoint.
  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = false
  }

  # The DNS-based endpoint is how the pipeline and operators outside the network reach the Kubernetes API. Every
  # request needs Google Cloud credentials with the IAM permission container.clusters.connect.
  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = true
    }
  }

  # Kubernetes service accounts can act as Google service accounts (identity.tf).
  workload_identity_config {
    workload_pool = local.workload_identity_pool
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    # Provides the standard-rwo StorageClass the platform components store their data in.
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  # Google Cloud Managed Service for Prometheus collects the metrics of workloads unless the platform runs its own
  # Prometheus.
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]

    managed_prometheus {
      enabled = !var.enable_observability
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_start_time
    }
  }

  enable_shielded_nodes = true

  # Terraform refuses to delete the production cluster until this is set to false and applied.
  deletion_protection = local.is_production

  depends_on = [google_project_service.required]
}

# -----------------------------------------------------------------------------
# Nodes
# -----------------------------------------------------------------------------

resource "google_container_node_pool" "primary" {
  project  = var.gcp_project_id
  name     = "primary"
  location = var.region
  cluster  = google_container_cluster.this.name

  # Nodes per zone when the pool is created, enough to reach node_min_count in total. Afterwards the cluster
  # autoscaler sets the size.
  initial_node_count = ceil(var.node_min_count / local.node_zone_count)

  # Limits for the whole pool, not per zone, so they mean the same as on the other clouds.
  autoscaling {
    total_min_node_count = var.node_min_count
    total_max_node_count = local.node_max_count
    location_policy      = "BALANCED"
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
    machine_type = local.node_machine_types[var.node_size]
    disk_size_gb = var.node_disk_size_gb
    disk_type    = "pd-balanced"
    image_type   = "COS_CONTAINERD"

    service_account = module.node_identity.service_account_email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    tags = [local.node_network_tag]

    labels = {
      "node.kubernetes.io/size" = var.node_size
    }

    resource_labels = local.common_labels

    # Pods get credentials through Workload Identity instead of the service account of the node.
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

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

# -----------------------------------------------------------------------------
# Ready for workloads
# -----------------------------------------------------------------------------

# Exists once the cluster can schedule pods that pull their images through the NAT gateway and whose admission
# webhooks the control plane can reach. Every platform component depends on it.
resource "terraform_data" "cluster_ready" {
  depends_on = [
    google_container_node_pool.primary,
    module.vpc,
    module.nat,
  ]
}
