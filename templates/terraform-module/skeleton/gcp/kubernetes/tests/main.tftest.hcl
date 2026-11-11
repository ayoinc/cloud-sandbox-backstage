mock_provider "google" {}

variables {
  project_name = "acme-platform"
  environment  = "dev"
  project_id   = "acme-platform-dev"
  region       = "us-central1"
}

run "defaults" {
  command = plan

  assert {
    condition     = google_container_cluster.main.name == "acme-platform-dev-gke" && google_container_cluster.main.location == "us-central1"
    error_message = "The cluster must be regional and named after the project and environment."
  }

  assert {
    condition     = google_container_cluster.main.enable_autopilot == true
    error_message = "The cluster must be Autopilot by default."
  }

  assert {
    condition     = google_container_cluster.main.network == "default"
    error_message = "Without a network the cluster must attach to the default network."
  }

  assert {
    condition     = google_container_cluster.main.private_cluster_config[0].enable_private_nodes == true && google_container_cluster.main.private_cluster_config[0].enable_private_endpoint == true
    error_message = "Nodes and the control plane endpoint must be private by default."
  }

  assert {
    condition     = google_container_cluster.main.master_authorized_networks_config[0].gcp_public_cidrs_access_enabled == false && length(google_container_cluster.main.master_authorized_networks_config[0].cidr_blocks) == 0
    error_message = "No external range may reach the control plane by default."
  }

  assert {
    condition     = google_container_cluster.main.workload_identity_config[0].workload_pool == "acme-platform-dev.svc.id.goog"
    error_message = "Workload Identity must use the project pool."
  }

  assert {
    condition     = google_container_cluster.main.release_channel[0].channel == "REGULAR" && google_container_cluster.main.deletion_protection == true
    error_message = "The cluster must use the regular channel and be protected against deletion."
  }

  assert {
    condition     = length(google_container_cluster.main.database_encryption) == 0
    error_message = "Without a key no application-layer secret encryption may be configured."
  }

  assert {
    condition     = length(google_container_node_pool.main) == 0
    error_message = "Autopilot clusters must not have managed node pools."
  }

  assert {
    condition     = google_service_account.nodes.account_id == "acme-platform-dev-gke" && google_project_iam_member.nodes.role == "roles/container.defaultNodeServiceAccount"
    error_message = "Nodes must run as a dedicated least-privilege service account."
  }

  assert {
    condition     = google_artifact_registry_repository.main[0].repository_id == "acme-platform-dev-images" && google_artifact_registry_repository.main[0].format == "DOCKER"
    error_message = "A Docker repository must be created by default."
  }

  assert {
    condition     = google_artifact_registry_repository.main[0].docker_config[0].immutable_tags == true
    error_message = "Image tags must be immutable by default."
  }

  assert {
    condition     = endswith(output.kubeconfig_command, "--internal-ip")
    error_message = "The kubeconfig command must use the internal endpoint for private clusters."
  }
}

run "null_network_inputs" {
  command = plan

  variables {
    network_name           = null
    subnet_name            = null
    pods_range_name        = null
    services_range_name    = null
    kms_key_id             = null
    master_ipv4_cidr_block = null
  }

  assert {
    condition     = google_container_cluster.main.network == "default"
    error_message = "A null network must fall back to the default network."
  }
}

run "standard_cluster" {
  command = plan

  variables {
    network_name            = "acme-platform-dev-vpc"
    subnet_name             = "acme-platform-dev-private"
    pods_range_name         = "acme-platform-dev-pods"
    services_range_name     = "acme-platform-dev-services"
    enable_autopilot        = false
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
    master_authorized_networks = [
      { cidr_block = "203.0.113.0/24", display_name = "office" },
    ]
    kms_key_id = "projects/acme-platform-dev/locations/us-central1/keyRings/acme/cryptoKeys/acme-key"
    node_pools = {
      general = {}
      batch = {
        machine_type = "n2-standard-8"
        min_count    = 0
        max_count    = 10
        spot         = true
        taints       = [{ key = "workload", value = "batch", effect = "NO_SCHEDULE" }]
      }
    }
  }

  assert {
    condition     = google_container_cluster.main.enable_autopilot == null && google_container_cluster.main.initial_node_count == 1
    error_message = "Standard clusters must start with the system pool."
  }

  assert {
    condition     = google_container_cluster.main.subnetwork == "acme-platform-dev-private" && google_container_cluster.main.ip_allocation_policy[0].cluster_secondary_range_name == "acme-platform-dev-pods"
    error_message = "The cluster must use the given subnet and secondary ranges."
  }

  assert {
    condition     = google_container_cluster.main.node_config[0].workload_metadata_config[0].mode == "GKE_METADATA" && google_container_cluster.main.node_config[0].image_type == "COS_CONTAINERD"
    error_message = "The system pool must be hardened."
  }

  assert {
    condition     = one(google_container_cluster.main.master_authorized_networks_config[0].cidr_blocks).cidr_block == "203.0.113.0/24"
    error_message = "The public endpoint must be restricted to the authorized networks."
  }

  assert {
    condition     = google_container_cluster.main.database_encryption[0].state == "ENCRYPTED"
    error_message = "Secrets must be encrypted with the given key."
  }

  assert {
    condition     = length(google_container_node_pool.main) == 2
    error_message = "One node pool must be created per entry."
  }

  assert {
    condition     = google_container_node_pool.main["general"].node_config[0].machine_type == "e2-standard-4" && google_container_node_pool.main["general"].autoscaling[0].max_node_count == 3
    error_message = "Node pool defaults must apply."
  }

  assert {
    condition     = google_container_node_pool.main["batch"].node_config[0].spot == true && length(google_container_node_pool.main["batch"].node_config[0].taint) == 1
    error_message = "Spot and taints must be configured on the batch pool."
  }

  assert {
    condition     = alltrue([for pool in google_container_node_pool.main : pool.management[0].auto_repair && pool.management[0].auto_upgrade])
    error_message = "Every pool must repair and upgrade automatically."
  }

  assert {
    condition     = alltrue([for pool in google_container_node_pool.main : pool.node_config[0].shielded_instance_config[0].enable_secure_boot])
    error_message = "Every pool must use secure boot."
  }

  assert {
    condition     = !endswith(output.kubeconfig_command, "--internal-ip")
    error_message = "The kubeconfig command must use the public endpoint when it exists."
  }
}

run "without_artifact_registry" {
  command = plan

  variables {
    enable_artifact_registry = false
  }

  assert {
    condition     = length(google_artifact_registry_repository.main) == 0 && output.artifact_registry_url == null
    error_message = "The repository must not be created when disabled."
  }
}

run "rejects_public_endpoint_without_allow_list" {
  command = plan

  variables {
    enable_private_endpoint = false
  }

  expect_failures = [google_container_cluster.main]
}

run "rejects_open_control_plane" {
  command = plan

  variables {
    master_authorized_networks = [{ cidr_block = "0.0.0.0/0" }]
  }

  expect_failures = [var.master_authorized_networks]
}

run "rejects_node_pools_on_autopilot" {
  command = plan

  variables {
    node_pools = { general = {} }
  }

  expect_failures = [google_container_cluster.main]
}
