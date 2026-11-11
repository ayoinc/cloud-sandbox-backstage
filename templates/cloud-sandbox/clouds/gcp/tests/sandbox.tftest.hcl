# Plan-only tests against mocked providers: no credentials, no resources.
# Run with: terraform init -backend=false && terraform test

mock_provider "google" {}

mock_provider "random" {}

variables {
  project_id      = "test-project"
  name            = "test-sandbox"
  environment     = "sandbox"
  region          = "us-central1"
  vpc_cidr        = "10.0.0.0/16"
  public_subnets  = 2
  private_subnets = 2
  include_bastion = false
  include_eks     = false
  include_rds     = false
}

run "root_module_plans" {
  command = plan

  assert {
    condition     = length(output.public_subnet_ids) == 2 && length(output.private_subnet_ids) == 2
    error_message = "The root module must expose one ID per subnet."
  }

  assert {
    condition     = output.bastion_instance_name == null && output.gke_cluster_name == null && output.cloudsql_connection_name == null
    error_message = "Outputs of components that are not included must be null."
  }
}

run "network_layout" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  assert {
    condition     = google_compute_network.this.auto_create_subnetworks == false
    error_message = "The network must only contain the subnets defined here."
  }

  assert {
    condition     = google_compute_subnetwork.public[*].ip_cidr_range == ["10.0.0.0/20", "10.0.16.0/20"]
    error_message = "Public subnets must be the first /20 blocks of the network range."
  }

  assert {
    condition     = google_compute_subnetwork.private[*].ip_cidr_range == ["10.0.128.0/20", "10.0.144.0/20"]
    error_message = "Private subnets must start at the ninth /20 block of the network range."
  }

  assert {
    condition     = alltrue(google_compute_subnetwork.private[*].private_ip_google_access)
    error_message = "Private subnets must reach Google APIs without external IP addresses."
  }

  assert {
    condition     = length(google_compute_router_nat.this) == 1
    error_message = "Private subnets need Cloud NAT."
  }

  assert {
    condition     = keys(google_project_service.this) == ["compute.googleapis.com"]
    error_message = "Only the Compute Engine API is needed for the network."
  }

  assert {
    condition     = length(google_compute_instance.bastion) == 0 && length(google_container_cluster.this) == 0 && length(google_sql_database_instance.this) == 0
    error_message = "Optional components must not be created unless included."
  }
}

run "public_only_network" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  variables {
    public_subnets  = 1
    private_subnets = 0
  }

  assert {
    condition     = length(google_compute_subnetwork.public) == 1 && length(google_compute_subnetwork.private) == 0
    error_message = "Subnet counts must follow the variables."
  }

  assert {
    condition     = length(google_compute_router_nat.this) == 0
    error_message = "No Cloud NAT is needed without private subnets or a bastion."
  }
}

run "bastion_has_no_external_ip" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  variables {
    private_subnets = 0
    include_bastion = true
  }

  assert {
    condition     = length(google_compute_instance.bastion[0].network_interface[0].access_config) == 0
    error_message = "The bastion must not have an external IP address."
  }

  assert {
    condition     = google_compute_instance.bastion[0].metadata["enable-oslogin"] == "TRUE"
    error_message = "The bastion must use OS Login."
  }

  assert {
    condition     = google_compute_firewall.bastion_iap_ssh[0].source_ranges == toset(["35.235.240.0/20"])
    error_message = "SSH must be open to the Identity-Aware Proxy range only."
  }

  assert {
    condition     = length(google_compute_router_nat.this) == 1
    error_message = "A bastion without an external IP address needs Cloud NAT."
  }
}

run "gke_nodes_are_private" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  variables {
    private_subnets = 0
    include_eks     = true
  }

  assert {
    condition     = length(google_compute_subnetwork.private) == 1
    error_message = "GKE needs a private subnet even when none were requested."
  }

  assert {
    condition     = google_container_cluster.this[0].private_cluster_config[0].enable_private_nodes
    error_message = "GKE nodes must not have external IP addresses."
  }

  assert {
    condition     = google_container_cluster.this[0].enable_autopilot
    error_message = "The cluster must be an Autopilot cluster."
  }

  assert {
    condition     = length(google_container_cluster.this[0].master_authorized_networks_config[0].cidr_blocks) == 0
    error_message = "The GKE API must not be open to external networks unless kubernetes_api_allowed_cidrs is set."
  }
}

run "cloudsql_is_private" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  variables {
    include_rds = true
  }

  assert {
    condition     = google_sql_database_instance.this[0].settings[0].ip_configuration[0].ipv4_enabled == false
    error_message = "The database must not have a public IP address."
  }

  assert {
    condition     = google_sql_database_instance.this[0].settings[0].ip_configuration[0].ssl_mode == "ENCRYPTED_ONLY"
    error_message = "The database must accept encrypted connections only."
  }

  assert {
    condition     = google_sql_database.this[0].name == "db_test_sandbox"
    error_message = "The database name is derived from the sandbox name."
  }
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    vpc_cidr = "10.0.0.0/28"
  }

  expect_failures = [var.vpc_cidr]
}
