# GCP Infrastructure Module
# This module provisions GCP resources for the infrastructure stack

{% if values.enable_networking %}
# VPC Network
resource "google_compute_network" "main" {
  name                    = "${var.name_prefix}-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private" {
  name          = "${var.name_prefix}-private-subnet"
  project       = var.project_id
  ip_cidr_range = cidrsubnet(var.vpc_cidr, 4, 0)
  region        = var.region
  network       = google_compute_network.main.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = cidrsubnet(var.vpc_cidr, 4, 1)
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = cidrsubnet(var.vpc_cidr, 4, 2)
  }
}

resource "google_compute_router" "main" {
  name    = "${var.name_prefix}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "main" {
  name                               = "${var.name_prefix}-nat"
  project                            = var.project_id
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
{% endif %}

{% if values.enable_kubernetes %}
# GKE Cluster
resource "google_container_cluster" "main" {
  name     = "${var.name_prefix}-gke"
  project  = var.project_id
  location = var.region

  network    = google_compute_network.main.name
  subnetwork = google_compute_subnetwork.private.name

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  resource_labels = var.common_labels
}

resource "google_container_node_pool" "primary" {
  name       = "${var.name_prefix}-node-pool"
  project    = var.project_id
  location   = var.region
  cluster    = google_container_cluster.main.name
  node_count = var.enable_autoscaling ? null : var.min_nodes

  dynamic "autoscaling" {
    for_each = var.enable_autoscaling ? [1] : []
    content {
      min_node_count = var.min_nodes
      max_node_count = var.max_nodes
    }
  }

  node_config {
    machine_type = var.node_instance_type
    disk_size_gb = 100

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = var.common_labels

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}
{% endif %}

{% if values.enable_database %}
# Cloud SQL PostgreSQL
resource "google_sql_database_instance" "main" {
  name             = "${var.name_prefix}-db"
  project          = var.project_id
  region           = var.region
  database_version = "POSTGRES_15"

  settings {
    tier = var.environment == "production" ? "db-custom-4-15360" : "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
    }

    backup_configuration {
      enabled = true
    }

    user_labels = var.common_labels
  }

  deletion_protection = var.environment == "production"
}

resource "google_sql_user" "main" {
  name     = "admin"
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  password = var.database_password
}
{% endif %}

{% if values.enable_storage %}
# Cloud Storage Bucket
resource "google_storage_bucket" "main" {
  name          = "${var.name_prefix}-storage-${var.environment}"
  project       = var.project_id
  location      = var.region
  force_destroy = var.environment != "production"

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = var.common_labels
}
{% endif %}

{% if values.enable_kms %}
# KMS Key Ring and Key
resource "google_kms_key_ring" "main" {
  name     = "${var.name_prefix}-keyring"
  project  = var.project_id
  location = var.region
}

resource "google_kms_crypto_key" "main" {
  name            = "${var.name_prefix}-key"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s" # 90 days

  labels = var.common_labels
}
{% endif %}

{% if values.enable_secrets_manager %}
# Secret Manager
resource "google_secret_manager_secret" "main" {
  secret_id = "${var.name_prefix}-secrets"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.common_labels
}
{% endif %}
