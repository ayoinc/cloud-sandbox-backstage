locals {
  # GKE nodes run in a private subnet.
  private_subnet_count = var.include_eks ? max(var.private_subnets, 1) : var.private_subnets

  # The address range is cut into 16 equal blocks: 0-3 public, 8-11 private.
  public_subnet_cidrs  = [for i in range(var.public_subnets) : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnet_cidrs = [for i in range(local.private_subnet_count) : cidrsubnet(var.vpc_cidr, 4, i + 8)]

  # VMs without an external IP address reach the internet through Cloud NAT.
  nat_enabled = local.private_subnet_count > 0 || var.include_bastion

  # Database names cannot contain hyphens.
  database_name = "db_${replace(var.name, "-", "_")}"

  services = toset(concat(
    ["compute.googleapis.com"],
    var.include_bastion ? ["iap.googleapis.com", "oslogin.googleapis.com"] : [],
    var.include_eks ? ["container.googleapis.com"] : [],
    var.include_rds ? ["sqladmin.googleapis.com", "servicenetworking.googleapis.com"] : [],
  ))
}

# The APIs the sandbox uses. They stay enabled when the sandbox is destroyed,
# because other workloads in the project may rely on them.
resource "google_project_service" "this" {
  for_each = local.services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = var.name
  auto_create_subnetworks = false

  depends_on = [google_project_service.this]
}

resource "google_compute_subnetwork" "public" {
  count = var.public_subnets

  project       = var.project_id
  name          = "${var.name}-public-${count.index + 1}"
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = local.public_subnet_cidrs[count.index]

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "private" {
  count = local.private_subnet_count

  project                  = var.project_id
  name                     = "${var.name}-private-${count.index + 1}"
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = local.private_subnet_cidrs[count.index]
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "this" {
  count = local.nat_enabled ? 1 : 0

  project = var.project_id
  name    = var.name
  region  = var.region
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "this" {
  count = local.nat_enabled ? 1 : 0

  project                            = var.project_id
  name                               = var.name
  region                             = var.region
  router                             = google_compute_router.this[0].name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "internal" {
  project     = var.project_id
  name        = "${var.name}-allow-internal"
  network     = google_compute_network.this.id
  description = "Traffic between resources inside the sandbox network"
  direction   = "INGRESS"

  source_ranges = [var.vpc_cidr]

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }
}

# -----------------------------------------------------------------------------
# Bastion host (optional)
# -----------------------------------------------------------------------------

data "google_compute_zones" "available" {
  count = var.include_bastion ? 1 : 0

  project = var.project_id
  region  = var.region
  status  = "UP"

  depends_on = [google_project_service.this]
}

resource "google_service_account" "bastion" {
  count = var.include_bastion ? 1 : 0

  project      = var.project_id
  account_id   = "${substr(var.name, 0, 20)}-bastion"
  display_name = "Bastion of the ${var.name} sandbox"
}

# 35.235.240.0/20 is the range Identity-Aware Proxy forwards TCP from, so SSH
# is open to authenticated IAP users only.
resource "google_compute_firewall" "bastion_iap_ssh" {
  count = var.include_bastion ? 1 : 0

  project     = var.project_id
  name        = "${var.name}-allow-iap-ssh"
  network     = google_compute_network.this.id
  description = "SSH to the bastion through Identity-Aware Proxy"
  direction   = "INGRESS"

  source_ranges           = ["35.235.240.0/20"]
  target_service_accounts = [google_service_account.bastion[0].email]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_instance" "bastion" {
  count = var.include_bastion ? 1 : 0

  project      = var.project_id
  name         = "${var.name}-bastion"
  zone         = data.google_compute_zones.available[0].names[0]
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  # No access_config block: the VM has no external IP address.
  network_interface {
    subnetwork = google_compute_subnetwork.public[0].id
  }

  metadata = {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "TRUE"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  service_account {
    email  = google_service_account.bastion[0].email
    scopes = ["cloud-platform"]
  }

  labels = {
    role = "bastion"
  }

  # A newer image must not replace a running bastion on the next apply.
  lifecycle {
    ignore_changes = [boot_disk[0].initialize_params[0].image]
  }
}

# -----------------------------------------------------------------------------
# GKE cluster (optional)
# -----------------------------------------------------------------------------

resource "google_service_account" "gke_nodes" {
  count = var.include_eks ? 1 : 0

  project      = var.project_id
  account_id   = "${substr(var.name, 0, 20)}-gke-nodes"
  display_name = "GKE nodes of the ${var.name} sandbox"
}

resource "google_project_iam_member" "gke_nodes" {
  count = var.include_eks ? 1 : 0

  project = var.project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

# Autopilot cluster: Google manages the nodes, which are private, shielded
# and use Workload Identity.
resource "google_container_cluster" "this" {
  count = var.include_eks ? 1 : 0

  project  = var.project_id
  name     = var.name
  location = var.region

  enable_autopilot = true

  network    = google_compute_network.this.id
  subnetwork = google_compute_subnetwork.private[0].id

  # A sandbox is meant to be thrown away.
  deletion_protection = false

  release_channel {
    channel = "REGULAR"
  }

  # VPC-native cluster; GKE picks the pod and service ranges.
  ip_allocation_policy {}

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.30.0.0/28"
  }

  # Only the listed networks can reach the API from outside the VPC network.
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.kubernetes_api_allowed_cidrs

      content {
        cidr_block   = cidr_blocks.value
        display_name = "allowed-${cidr_blocks.key}"
      }
    }
  }

  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.gke_nodes[0].email
      oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  resource_labels = {
    component = "gke"
  }

  # Nodes without external IP addresses pull images through Cloud NAT.
  depends_on = [
    google_project_service.this,
    google_compute_router_nat.this,
    google_project_iam_member.gke_nodes,
  ]
}

# -----------------------------------------------------------------------------
# Cloud SQL for PostgreSQL (optional)
# -----------------------------------------------------------------------------

# Address range reserved for Google-managed services; Cloud SQL gets its
# private IP address from it.
resource "google_compute_global_address" "private_services" {
  count = var.include_rds ? 1 : 0

  project       = var.project_id
  name          = "${var.name}-private-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.this.id
}

resource "google_service_networking_connection" "private_services" {
  count = var.include_rds ? 1 : 0

  network                 = google_compute_network.this.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services[0].name]

  depends_on = [google_project_service.this]
}

resource "google_sql_database_instance" "this" {
  count = var.include_rds ? 1 : 0

  project          = var.project_id
  name             = "${var.name}-postgresql"
  region           = var.region
  database_version = "POSTGRES_16"

  # A sandbox is meant to be thrown away.
  deletion_protection = false

  settings {
    tier    = "db-custom-1-3840"
    edition = "ENTERPRISE"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.this.id
      ssl_mode        = "ENCRYPTED_ONLY"
    }

    backup_configuration {
      enabled = true
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "log_lock_waits"
      value = "on"
    }

    database_flags {
      name  = "log_temp_files"
      value = "0"
    }

    database_flags {
      name  = "log_min_messages"
      value = "warning"
    }
  }

  depends_on = [google_service_networking_connection.private_services]
}

resource "google_sql_database" "this" {
  count = var.include_rds ? 1 : 0

  project  = var.project_id
  name     = local.database_name
  instance = google_sql_database_instance.this[0].name
}

# The password lives in the Terraform state; read it with
# `terraform output -raw cloudsql_admin_password`.
resource "random_password" "cloudsql" {
  count = var.include_rds ? 1 : 0

  length  = 32
  special = false
}

resource "google_sql_user" "admin" {
  count = var.include_rds ? 1 : 0

  project  = var.project_id
  name     = "sandbox_admin"
  instance = google_sql_database_instance.this[0].name
  password = random_password.cloudsql[0].result
}
