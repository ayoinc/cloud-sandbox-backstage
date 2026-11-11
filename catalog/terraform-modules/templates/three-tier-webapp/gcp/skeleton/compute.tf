# -----------------------------------------------------------------------------
# Application tier. compute_type selects how the application runs:
#   gke-autopilot  GKE Autopilot cluster, Google sizes the nodes to the pods
#   gke-standard   GKE Standard cluster with an autoscaled node pool
#   mig            Container-Optimized OS instances in a regional managed
#                  instance group behind the load balancer
# -----------------------------------------------------------------------------

# --- GKE Autopilot (gke-autopilot) ---------------------------------------------

resource "google_container_cluster" "autopilot" {
  count = var.compute_type == "gke-autopilot" ? 1 : 0

  name     = "${local.name_prefix}-gke"
  location = var.region

  enable_autopilot = true

  network    = module.vpc.network_id
  subnetwork = module.vpc.subnet_ids["app"]

  ip_allocation_policy {
    cluster_secondary_range_name  = local.pods_range_name
    services_secondary_range_name = local.services_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.gke_master_ipv4_cidr_block
  }

  # Without entries only addresses inside the VPC reach the control plane.
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.gke_master_authorized_networks

      content {
        display_name = cidr_blocks.value.display_name
        cidr_block   = cidr_blocks.value.cidr_block
      }
    }
  }

  release_channel {
    channel = var.gke_release_channel
  }

  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = module.app_service_account.service_account_email
      oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    }
  }

  deletion_protection = local.is_production

  depends_on = [google_project_service.required]
}

# --- GKE Standard (gke-standard) -----------------------------------------------

resource "google_container_cluster" "standard" {
  count = var.compute_type == "gke-standard" ? 1 : 0

  name     = "${local.name_prefix}-gke"
  location = var.region

  # The cluster's own node pool is replaced by the autoscaled pool below.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = module.vpc.network_id
  subnetwork = module.vpc.subnet_ids["app"]

  networking_mode   = "VPC_NATIVE"
  datapath_provider = "ADVANCED_DATAPATH"

  ip_allocation_policy {
    cluster_secondary_range_name  = local.pods_range_name
    services_secondary_range_name = local.services_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.gke_master_ipv4_cidr_block
  }

  # Without entries only addresses inside the VPC reach the control plane.
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.gke_master_authorized_networks

      content {
        display_name = cidr_blocks.value.display_name
        cidr_block   = cidr_blocks.value.cidr_block
      }
    }
  }

  release_channel {
    channel = var.gke_release_channel
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  enable_shielded_nodes = true

  deletion_protection = local.is_production

  depends_on = [google_project_service.required]
}

resource "google_container_node_pool" "standard" {
  count = var.compute_type == "gke-standard" ? 1 : 0

  name     = "${local.name_prefix}-nodes"
  location = var.region
  cluster  = google_container_cluster.standard[0].name

  # Nodes per zone at creation. The autoscaler then keeps the total number of
  # nodes across the region's zones between min_nodes and max_nodes.
  initial_node_count = 1

  autoscaling {
    total_min_node_count = var.min_nodes
    total_max_node_count = local.max_nodes
    location_policy      = "BALANCED"
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type
    image_type   = "COS_CONTAINERD"
    disk_size_gb = 100
    disk_type    = "pd-balanced"

    service_account = module.app_service_account.service_account_email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

# Pods running as kubernetes_namespace/kubernetes_service_account act as the
# application's service account, so they can reach Cloud SQL and read the
# database password.
resource "google_service_account_iam_member" "workload_identity" {
  count = local.runs_gke ? 1 : 0

  service_account_id = module.app_service_account.service_account_name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[${var.kubernetes_namespace}/${var.kubernetes_service_account}]"

  depends_on = [
    google_container_cluster.autopilot,
    google_container_cluster.standard,
  ]
}

# --- Managed instance group (mig) ----------------------------------------------

resource "google_compute_instance_template" "app" {
  count = local.runs_instances ? 1 : 0

  name_prefix  = "${local.name_prefix}-app-"
  description  = "Runs ${var.container_image} on Container-Optimized OS"
  machine_type = var.machine_type
  region       = var.region
  tags         = [local.app_network_tag]

  disk {
    source_image = var.instance_image
    boot         = true
    auto_delete  = true
    disk_type    = "pd-balanced"
    disk_size_gb = 20
  }

  # No access_config: the instances have no public address and reach the
  # internet through Cloud NAT.
  network_interface {
    subnetwork = module.vpc.subnet_self_links["app"]
  }

  service_account {
    email  = module.app_service_account.service_account_email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    block-project-ssh-keys = "true"
    enable-oslogin         = "true"
    google-logging-enabled = "true"

    # Container-Optimized OS only accepts SSH by default, so the application
    # port is opened before the container is started.
    startup-script = <<-EOT
      #!/bin/bash
      set -eu
      if ! iptables -w -C INPUT -p tcp --dport ${var.container_port} -j ACCEPT 2>/dev/null; then
        iptables -w -A INPUT -p tcp --dport ${var.container_port} -j ACCEPT
      fi
      if docker container inspect app >/dev/null 2>&1; then
        docker rm --force app
      fi
      docker run --detach --name app --restart always \
        --publish ${var.container_port}:${var.container_port} \
        ${var.container_image}
    EOT
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "app" {
  count = local.runs_instances ? 1 : 0

  name               = "${local.name_prefix}-app"
  region             = var.region
  base_instance_name = "${local.name_prefix}-app"

  version {
    instance_template = google_compute_instance_template.app[0].id
  }

  named_port {
    name = "http"
    port = var.container_port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.app.id
    initial_delay_sec = 180
  }

  # New instances are added before old ones are removed. A regional group needs
  # a surge of at least one instance per zone.
  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 3
    max_unavailable_fixed = 0
  }

  depends_on = [module.vpc]
}

resource "google_compute_region_autoscaler" "app" {
  count = local.runs_instances ? 1 : 0

  name   = "${local.name_prefix}-app"
  region = var.region
  target = google_compute_region_instance_group_manager.app[0].id

  autoscaling_policy {
    min_replicas    = var.min_nodes
    max_replicas    = local.max_nodes
    cooldown_period = 120

    cpu_utilization {
      target = var.cpu_target / 100
    }
  }
}
