terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    # Configure your backend
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.region
}

locals {
  common_labels = {
    project     = var.name
    environment = var.environment
    managed-by  = "terraform"
  }
}

# Get existing VPC
data "google_compute_network" "main" {
  name = "${var.name}-${var.environment}-vpc"
}

data "google_compute_subnetwork" "gke" {
  name   = "${var.name}-${var.environment}-gke"
  region = var.region
}

# Service Account for GKE nodes
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.name}-${var.environment}-gke"
  display_name = "GKE Node Service Account for ${var.name}"
}

resource "google_project_iam_member" "gke_nodes" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader",
  ])
  project = var.gcp_project
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Artifact Registry for container images
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "${var.name}-${var.environment}"
  description   = "Container registry for ${var.name}"
  format        = "DOCKER"

  labels = local.common_labels
}

# GKE Cluster - Autopilot Mode
resource "google_container_cluster" "autopilot" {
  count    = var.cluster_mode == "autopilot" ? 1 : 0
  name     = "${var.name}-${var.environment}"
  location = var.region

  enable_autopilot = true

  network    = data.google_compute_network.main.id
  subnetwork = data.google_compute_subnetwork.gke.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.environment == "production"
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  release_channel {
    channel = var.environment == "production" ? "STABLE" : "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project}.svc.id.goog"
  }

  resource_labels = local.common_labels

  deletion_protection = var.environment == "production"
}

# GKE Cluster - Standard Mode
resource "google_container_cluster" "standard" {
  count    = var.cluster_mode == "standard" ? 1 : 0
  name     = "${var.name}-${var.environment}"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = data.google_compute_network.main.id
  subnetwork = data.google_compute_subnetwork.gke.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.environment == "production"
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  release_channel {
    channel = var.environment == "production" ? "STABLE" : "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project}.svc.id.goog"
  }

  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 100
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 1
      maximum       = 1000
    }
  }

  resource_labels = local.common_labels

  deletion_protection = var.environment == "production"
}

# Node Pool for Standard Mode
resource "google_container_node_pool" "primary" {
  count      = var.cluster_mode == "standard" ? 1 : 0
  name       = "primary"
  location   = var.region
  cluster    = google_container_cluster.standard[0].name
  node_count = var.node_count

  autoscaling {
    min_node_count = 1
    max_node_count = var.node_count * 3
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = var.environment != "production"
    machine_type = var.machine_type
    disk_size_gb = 100
    disk_type    = "pd-standard"

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
  }
}
