# Plans the stack against mocked providers, so the tests need no Google Cloud project and no cluster.
# Values not set in a run come from terraform.tfvars.

mock_provider "google" {}

mock_provider "kubernetes" {}

mock_provider "helm" {}

run "configured_values" {
  command = plan

  assert {
    condition     = google_container_cluster.this.name == local.cluster_name && google_container_cluster.this.location == var.region
    error_message = "The cluster is regional and named after the project and the environment."
  }

  assert {
    condition     = google_container_cluster.this.min_master_version == var.kubernetes_version
    error_message = "The control plane is created with kubernetes_version."
  }

  assert {
    condition = (
      google_container_node_pool.primary.autoscaling[0].total_min_node_count == var.node_min_count &&
      google_container_node_pool.primary.autoscaling[0].total_max_node_count == max(var.node_min_count, var.node_max_count)
    )
    error_message = "node_min_count and node_max_count limit the node pool as a whole."
  }

  assert {
    condition     = google_container_node_pool.primary.node_config[0].machine_type == local.node_machine_types[var.node_size]
    error_message = "The nodes use the machine type of the chosen node_size."
  }

  assert {
    condition     = google_container_cluster.this.datapath_provider == (var.enable_network_policies ? "ADVANCED_DATAPATH" : "LEGACY_DATAPATH")
    error_message = "The cluster uses GKE Dataplane V2 exactly when enable_network_policies is true."
  }

  assert {
    condition     = local.cloud.network_policy_enforced == var.enable_network_policies
    error_message = "NetworkPolicy objects are enforced exactly when enable_network_policies is true."
  }

  assert {
    condition     = length(module.external_dns_identity) == (var.enable_external_dns ? 1 : 0)
    error_message = "The service account of external-dns exists exactly when enable_external_dns is true."
  }

  assert {
    condition     = google_container_cluster.this.private_cluster_config[0].enable_private_nodes && google_container_cluster.this.private_cluster_config[0].enable_private_endpoint
    error_message = "Nodes and the IP-based endpoint of the control plane are private."
  }

  assert {
    condition     = google_container_cluster.this.workload_identity_config[0].workload_pool == "${var.gcp_project_id}.svc.id.goog"
    error_message = "Workload Identity uses the pool of the project."
  }

  assert {
    condition     = google_container_node_pool.primary.node_config[0].workload_metadata_config[0].mode == "GKE_METADATA"
    error_message = "The nodes run the GKE metadata server that Workload Identity needs."
  }
}

run "node_size_small" {
  command = plan

  variables {
    node_size      = "small"
    node_min_count = 1
    node_max_count = 4
  }

  assert {
    condition     = google_container_node_pool.primary.node_config[0].machine_type == "e2-custom-2-4096"
    error_message = "small nodes are e2-custom-2-4096 (2 vCPU, 4 GB)."
  }

  assert {
    condition = (
      google_container_node_pool.primary.autoscaling[0].total_min_node_count == 1 &&
      google_container_node_pool.primary.autoscaling[0].total_max_node_count == 4
    )
    error_message = "node_min_count and node_max_count are the limits of the node pool."
  }

  assert {
    condition     = google_container_node_pool.primary.initial_node_count == 1
    error_message = "The node pool starts with one node in each of the three zones."
  }
}

run "node_size_medium" {
  command = plan

  variables {
    node_size = "medium"
  }

  assert {
    condition     = google_container_node_pool.primary.node_config[0].machine_type == "e2-standard-4"
    error_message = "medium nodes are e2-standard-4 (4 vCPU, 16 GB)."
  }
}

run "node_size_large" {
  command = plan

  variables {
    node_size          = "large"
    node_min_count     = 7
    node_max_count     = 30
    kubernetes_version = "1.37"
  }

  assert {
    condition     = google_container_node_pool.primary.node_config[0].machine_type == "e2-standard-8"
    error_message = "large nodes are e2-standard-8 (8 vCPU, 32 GB)."
  }

  assert {
    condition     = google_container_node_pool.primary.initial_node_count == 3
    error_message = "Seven nodes over three zones start as three nodes per zone."
  }

  assert {
    condition     = google_container_cluster.this.min_master_version == "1.37"
    error_message = "The control plane follows kubernetes_version."
  }
}

run "maximum_below_minimum_counts_as_minimum" {
  command = plan

  variables {
    node_min_count = 5
    node_max_count = 3
  }

  assert {
    condition = (
      google_container_node_pool.primary.autoscaling[0].total_min_node_count == 5 &&
      google_container_node_pool.primary.autoscaling[0].total_max_node_count == 5
    )
    error_message = "A maximum below the minimum is raised to the minimum."
  }
}

run "largest_node_counts_of_the_form" {
  command = plan

  variables {
    node_min_count = 100
    node_max_count = 100
  }

  assert {
    condition     = google_container_node_pool.primary.initial_node_count == 34
    error_message = "One hundred nodes over three zones start as 34 nodes per zone."
  }

  assert {
    condition     = google_container_node_pool.primary.autoscaling[0].total_max_node_count == 100
    error_message = "The form's largest node count is accepted."
  }
}

run "release_channel_is_set_when_chosen" {
  command = plan

  variables {
    release_channel = "STABLE"
  }

  assert {
    condition     = google_container_cluster.this.release_channel[0].channel == "STABLE"
    error_message = "release_channel enrols the cluster in that channel."
  }
}

run "ingress_nginx" {
  command = plan

  variables {
    ingress_controller = "nginx"
  }

  assert {
    condition     = length(helm_release.ingress_nginx) == 1 && length(helm_release.traefik) == 0
    error_message = "nginx installs ingress-nginx and not Traefik."
  }
}

run "ingress_traefik" {
  command = plan

  variables {
    ingress_controller = "traefik"
  }

  assert {
    condition     = length(helm_release.ingress_nginx) == 0 && length(helm_release.traefik) == 1
    error_message = "traefik installs Traefik and not ingress-nginx."
  }
}

run "ingress_none" {
  command = plan

  variables {
    ingress_controller = "none"
  }

  assert {
    condition     = length(helm_release.ingress_nginx) == 0 && length(helm_release.traefik) == 0
    error_message = "none installs no ingress controller."
  }
}

run "all_components_on_in_production" {
  command = plan

  variables {
    environment                   = "production"
    enable_gitops                 = true
    enable_observability          = true
    enable_service_mesh           = true
    enable_cert_manager           = true
    enable_external_dns           = true
    ingress_controller            = "nginx"
    enable_pod_security_standards = true
    enable_network_policies       = true
    enable_opa                    = true
    enable_vault_integration      = true
  }

  assert {
    condition     = google_container_cluster.this.deletion_protection
    error_message = "The production cluster is protected against deletion."
  }

  assert {
    condition     = google_container_cluster.this.datapath_provider == "ADVANCED_DATAPATH"
    error_message = "enable_network_policies creates the cluster with GKE Dataplane V2."
  }

  assert {
    condition     = local.cloud.network_policy_enforced
    error_message = "The platform components are told that NetworkPolicy objects are enforced."
  }

  assert {
    condition     = length(module.external_dns_identity) == 1
    error_message = "enable_external_dns creates the Google service account of external-dns."
  }

  assert {
    condition     = contains(keys(local.cloud.external_dns.service_account_annotations), "iam.gke.io/gcp-service-account")
    error_message = "The Kubernetes service account of external-dns is annotated with its Google service account."
  }

  assert {
    condition     = contains(keys(google_project_service.required), "dns.googleapis.com")
    error_message = "enable_external_dns enables the Cloud DNS API."
  }

  assert {
    condition     = length(kubernetes_namespace_v1.platform) == 8
    error_message = "Every platform component gets its namespace."
  }
}

run "all_components_off" {
  command = plan

  variables {
    environment                   = "dev"
    enable_gitops                 = false
    enable_observability          = false
    enable_service_mesh           = false
    enable_cert_manager           = false
    enable_external_dns           = false
    ingress_controller            = "none"
    enable_pod_security_standards = false
    enable_network_policies       = false
    enable_opa                    = false
    enable_vault_integration      = false
  }

  assert {
    condition     = !google_container_cluster.this.deletion_protection
    error_message = "Clusters outside production can be deleted by Terraform."
  }

  assert {
    condition     = google_container_cluster.this.datapath_provider == "LEGACY_DATAPATH"
    error_message = "Without network policies the cluster does not use GKE Dataplane V2."
  }

  assert {
    condition     = !local.cloud.network_policy_enforced
    error_message = "The platform components are told that NetworkPolicy objects are not enforced."
  }

  assert {
    condition     = length(module.external_dns_identity) == 0 && length(local.cloud.external_dns.service_account_annotations) == 0
    error_message = "No service account is created for external-dns when it is disabled."
  }

  assert {
    condition     = !contains(keys(google_project_service.required), "dns.googleapis.com")
    error_message = "The Cloud DNS API is only enabled for external-dns."
  }

  assert {
    condition     = length(kubernetes_namespace_v1.platform) == 0
    error_message = "No platform namespace is created when every component is disabled."
  }
}

run "long_names_fit_the_limits" {
  command = plan

  variables {
    project_name = "abcdefghijklmnop"
    environment  = "production"
  }

  assert {
    condition     = length(google_container_cluster.this.name) <= 40
    error_message = "A GKE cluster name has at most 40 characters."
  }

  assert {
    condition     = length("${local.account_prefix}-nodes") <= 30 && length("${local.account_prefix}-dns") <= 30
    error_message = "A service account ID has at most 30 characters."
  }
}
