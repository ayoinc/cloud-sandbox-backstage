# =============================================================================
# GCP GKE - Terraform Tests
# =============================================================================
# Uses Terraform native testing framework with output.* references.
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Mock Provider for Testing
# -----------------------------------------------------------------------------
mock_provider "google" {
  alias = "mock"
}

# -----------------------------------------------------------------------------
# Test Variables
# -----------------------------------------------------------------------------
variables {
  name        = "test-gke"
  environment = "dev"
  region      = "us-central1"
  project_id  = "test-project-123"
  owner       = "platform-team"

  # Cluster mode
  cluster_mode = "standard"

  # Network configuration
  network_id          = "projects/test-project-123/global/networks/test-vpc"
  subnet_id           = "projects/test-project-123/regions/us-central1/subnetworks/test-subnet"
  pods_range_name     = "pods"
  services_range_name = "services"

  # Private cluster
  enable_private_endpoint = false
  master_ipv4_cidr_block  = "172.16.0.0/28"
  master_authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "Internal networks"
    }
  ]

  # Release channel
  release_channel = "REGULAR"

  # Security
  enable_network_policy = true

  # Cluster autoscaling
  enable_cluster_autoscaling = true
  autoscaling_cpu_min        = 2
  autoscaling_cpu_max        = 50
  autoscaling_memory_min     = 4
  autoscaling_memory_max     = 100

  # Node pool
  node_count            = 3
  node_pool_min_count   = 1
  node_pool_max_count   = 10
  machine_type          = "e2-standard-4"
  disk_size_gb          = 100
  disk_type             = "pd-standard"
  image_type            = "COS_CONTAINERD"
  use_preemptible_nodes = false
  use_spot_nodes        = false

  # Upgrade settings
  max_surge       = 1
  max_unavailable = 0

  # Taints
  node_taints = []

  # Additional node pools
  additional_node_pools = {}

  # Maintenance
  maintenance_start_time = "2024-01-01T04:00:00Z"
  maintenance_end_time   = "2024-01-01T08:00:00Z"
  maintenance_recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"

  # Artifact Registry
  create_artifact_registry     = true
  artifact_registry_keep_count = 10

  # Labels
  labels = {
    test-label = "test-value"
  }
}

# -----------------------------------------------------------------------------
# Test: GKE Module Plan Succeeds
# -----------------------------------------------------------------------------
run "gke_plan_succeeds" {
  command = plan

  providers = {
    google = google.mock
  }

  assert {
    condition     = output.cluster_name != ""
    error_message = "Cluster name should not be empty"
  }

  assert {
    condition     = output.cluster_id != ""
    error_message = "Cluster ID should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: GKE Naming Convention
# -----------------------------------------------------------------------------
run "gke_naming_convention" {
  command = plan

  providers = {
    google = google.mock
  }

  assert {
    condition     = output.cluster_name == "test-gke-dev"
    error_message = "Cluster name should follow convention: {name}-{environment}"
  }
}

# -----------------------------------------------------------------------------
# Test: Service Account Created
# -----------------------------------------------------------------------------
run "service_account_created" {
  command = plan

  providers = {
    google = google.mock
  }

  assert {
    condition     = output.service_account_email != ""
    error_message = "Service account email should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: Cluster Mode - Standard
# -----------------------------------------------------------------------------
run "cluster_mode_standard" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    cluster_mode = "standard"
  }

  assert {
    condition     = output.cluster_mode == "standard"
    error_message = "Cluster mode should be 'standard'"
  }

  assert {
    condition     = output.primary_node_pool_name == "primary"
    error_message = "Primary node pool should be created for standard mode"
  }
}

# -----------------------------------------------------------------------------
# Test: Cluster Mode - Autopilot
# -----------------------------------------------------------------------------
run "cluster_mode_autopilot" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    cluster_mode = "autopilot"
  }

  assert {
    condition     = output.cluster_mode == "autopilot"
    error_message = "Cluster mode should be 'autopilot'"
  }

  assert {
    condition     = output.primary_node_pool_name == null
    error_message = "Primary node pool should be null for autopilot mode"
  }
}

# -----------------------------------------------------------------------------
# Test: Artifact Registry Created When Enabled
# -----------------------------------------------------------------------------
run "artifact_registry_created_when_enabled" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    create_artifact_registry = true
  }

  assert {
    condition     = output.artifact_registry_id != null
    error_message = "Artifact Registry should be created when enabled"
  }

  assert {
    condition     = output.artifact_registry_url != null
    error_message = "Artifact Registry URL should not be null"
  }
}

# -----------------------------------------------------------------------------
# Test: Artifact Registry NOT Created When Disabled
# -----------------------------------------------------------------------------
run "artifact_registry_not_created_when_disabled" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    create_artifact_registry = false
  }

  assert {
    condition     = output.artifact_registry_id == null
    error_message = "Artifact Registry should not be created when disabled"
  }
}

# -----------------------------------------------------------------------------
# Test: Workload Identity Pool
# -----------------------------------------------------------------------------
run "workload_identity_pool" {
  command = plan

  providers = {
    google = google.mock
  }

  assert {
    condition     = output.workload_identity_pool == "test-project-123.svc.id.goog"
    error_message = "Workload Identity pool should match project ID"
  }
}

# -----------------------------------------------------------------------------
# Test: GKE Info Summary
# -----------------------------------------------------------------------------
run "gke_info_summary" {
  command = plan

  providers = {
    google = google.mock
  }

  assert {
    condition     = output.gke_info != null
    error_message = "GKE info summary should not be null"
  }

  assert {
    condition     = output.gke_info.location == "us-central1"
    error_message = "GKE info location should match input"
  }

  assert {
    condition     = output.gke_info.mode == "standard"
    error_message = "GKE info mode should match input"
  }
}

# -----------------------------------------------------------------------------
# Test: Environment - Development
# -----------------------------------------------------------------------------
run "environment_dev" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    environment = "dev"
  }

  assert {
    condition     = output.cluster_name == "test-gke-dev"
    error_message = "Development environment should be reflected in cluster name"
  }
}

# -----------------------------------------------------------------------------
# Test: Environment - Production
# -----------------------------------------------------------------------------
run "environment_prod" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    environment = "prod"
  }

  assert {
    condition     = output.cluster_name == "test-gke-prod"
    error_message = "Production environment should be reflected in cluster name"
  }
}

# -----------------------------------------------------------------------------
# Test: Different Region
# -----------------------------------------------------------------------------
run "different_region" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    region = "europe-west1"
  }

  assert {
    condition     = output.cluster_location == "europe-west1"
    error_message = "Cluster should be created in the specified region"
  }
}

# -----------------------------------------------------------------------------
# Test: Get Credentials Command
# -----------------------------------------------------------------------------
run "get_credentials_command" {
  command = plan

  providers = {
    google = google.mock
  }

  assert {
    condition     = output.get_credentials_command != ""
    error_message = "Get credentials command should not be empty"
  }

  assert {
    condition     = can(regex("gcloud container clusters get-credentials", output.get_credentials_command))
    error_message = "Get credentials command should contain gcloud command"
  }
}

# -----------------------------------------------------------------------------
# Test: Custom Labels
# -----------------------------------------------------------------------------
run "custom_labels" {
  command = plan

  providers = {
    google = google.mock
  }

  variables {
    labels = {
      cost-center = "engineering"
      project     = "infrastructure"
    }
  }

  assert {
    condition     = output.gke_info != null
    error_message = "GKE cluster should be created with custom labels"
  }
}
