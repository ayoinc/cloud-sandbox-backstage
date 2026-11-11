# Plans the stack against mocked providers, so the tests need no Google Cloud project.
# Values not set in a run come from terraform.tfvars.

mock_provider "google" {}

mock_provider "random" {}

mock_provider "tls" {}

run "configured_values" {
  command = plan

  assert {
    condition     = length(google_container_cluster.autopilot) == (var.compute_type == "gke-autopilot" ? 1 : 0)
    error_message = "An Autopilot cluster exists exactly when compute_type is gke-autopilot."
  }

  assert {
    condition     = length(google_container_node_pool.standard) == (var.compute_type == "gke-standard" ? 1 : 0)
    error_message = "A node pool exists exactly when compute_type is gke-standard."
  }

  assert {
    condition     = length(google_compute_region_instance_group_manager.app) == (var.compute_type == "mig" ? 1 : 0)
    error_message = "A managed instance group exists exactly when compute_type is mig."
  }

  assert {
    condition     = length(google_compute_security_policy.edge) == (var.enable_cloud_armor ? 1 : 0)
    error_message = "A Cloud Armor policy exists exactly when enable_cloud_armor is true."
  }

  assert {
    condition     = google_compute_backend_service.app.enable_cdn == var.enable_cloud_cdn
    error_message = "Cloud CDN on the backend service follows enable_cloud_cdn."
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].ip_configuration[0].ipv4_enabled == false
    error_message = "The database has no public address."
  }
}

run "gke_autopilot" {
  command = plan

  variables {
    compute_type = "gke-autopilot"
  }

  assert {
    condition     = length(google_container_cluster.autopilot) == 1 && length(google_container_cluster.standard) == 0 && length(google_compute_region_instance_group_manager.app) == 0
    error_message = "gke-autopilot creates only the Autopilot cluster."
  }

  assert {
    condition     = google_container_cluster.autopilot[0].enable_autopilot
    error_message = "The cluster runs in Autopilot mode."
  }

  assert {
    condition     = contains(keys(google_project_service.required), "container.googleapis.com")
    error_message = "The Kubernetes Engine API is enabled for the GKE compute types."
  }

  assert {
    condition     = google_compute_health_check.app.http_health_check[0].port_specification == "USE_SERVING_PORT"
    error_message = "Pods are checked on the port they serve."
  }

  assert {
    condition     = length(google_service_account_iam_member.workload_identity) == 1
    error_message = "Pods can act as the application's service account."
  }
}

run "gke_standard" {
  command = plan

  variables {
    compute_type = "gke-standard"
    machine_type = "e2-standard-4"
    min_nodes    = 3
    max_nodes    = 9
  }

  assert {
    condition     = length(google_container_cluster.standard) == 1 && length(google_container_cluster.autopilot) == 0 && length(google_compute_region_instance_group_manager.app) == 0
    error_message = "gke-standard creates only the Standard cluster."
  }

  assert {
    condition     = google_container_node_pool.standard[0].autoscaling[0].total_min_node_count == 3 && google_container_node_pool.standard[0].autoscaling[0].total_max_node_count == 9
    error_message = "min_nodes and max_nodes bound the node pool autoscaler."
  }

  assert {
    condition     = google_container_node_pool.standard[0].node_config[0].machine_type == "e2-standard-4"
    error_message = "machine_type sets the machine type of the nodes."
  }
}

run "gke_with_endpoint_groups" {
  command = plan

  variables {
    compute_type  = "gke-standard"
    gke_neg_zones = ["us-central1-a", "us-central1-b"]
  }

  assert {
    condition     = length(data.google_compute_network_endpoint_group.app) == 2
    error_message = "One network endpoint group per zone in gke_neg_zones is attached to the load balancer."
  }
}

run "managed_instance_group" {
  command = plan

  variables {
    compute_type  = "mig"
    gke_neg_zones = ["us-central1-a"]
    machine_type  = "e2-small"
    min_nodes     = 1
    max_nodes     = 4
  }

  assert {
    condition     = length(google_compute_region_instance_group_manager.app) == 1 && length(google_container_cluster.autopilot) == 0 && length(google_container_cluster.standard) == 0
    error_message = "mig creates a managed instance group and no cluster."
  }

  assert {
    condition     = google_compute_region_autoscaler.app[0].autoscaling_policy[0].min_replicas == 1 && google_compute_region_autoscaler.app[0].autoscaling_policy[0].max_replicas == 4
    error_message = "min_nodes and max_nodes bound the instance group autoscaler."
  }

  assert {
    condition     = google_compute_instance_template.app[0].machine_type == "e2-small"
    error_message = "machine_type sets the machine type of the instances."
  }

  assert {
    condition     = length(data.google_compute_network_endpoint_group.app) == 0
    error_message = "No GKE network endpoint group is looked up for mig, even when gke_neg_zones is set."
  }

  assert {
    condition     = !contains(keys(google_project_service.required), "container.googleapis.com")
    error_message = "The Kubernetes Engine API is not enabled for mig."
  }

  assert {
    condition     = google_compute_health_check.app.http_health_check[0].port == var.container_port
    error_message = "Instances are checked on the application port."
  }
}

run "production_mysql_with_edge_services" {
  command = plan

  variables {
    project_name       = "abcdefghijklmnop"
    environment        = "production"
    database_engine    = "MYSQL"
    high_availability  = true
    enable_cloud_armor = true
    enable_cloud_cdn   = true
  }

  assert {
    condition     = length(google_compute_security_policy.edge) == 1 && google_compute_backend_service.app.enable_cdn
    error_message = "enable_cloud_armor and enable_cloud_cdn create the security policy and turn on Cloud CDN."
  }

  assert {
    condition     = google_sql_database_instance.main.database_version == "MYSQL_8_0"
    error_message = "MYSQL selects a MySQL database version."
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].availability_type == "REGIONAL" && google_sql_database_instance.main.settings[0].backup_configuration[0].binary_log_enabled
    error_message = "high_availability creates a regional MySQL instance with binary logging."
  }

  assert {
    condition     = google_sql_database_instance.main.deletion_protection
    error_message = "The production database is protected against deletion."
  }

  assert {
    condition     = length("${local.name_prefix}-app") <= 30
    error_message = "The service account ID fits in 30 characters for the longest project name."
  }
}

run "postgres_without_edge_services" {
  command = plan

  variables {
    database_engine    = "POSTGRES"
    database_tier      = "db-custom-1-3840"
    high_availability  = false
    enable_cloud_armor = false
    enable_cloud_cdn   = false
  }

  assert {
    condition     = length(google_compute_security_policy.edge) == 0 && !google_compute_backend_service.app.enable_cdn
    error_message = "No security policy and no CDN when both are disabled."
  }

  assert {
    condition     = google_sql_database_instance.main.database_version == "POSTGRES_16" && google_sql_database_instance.main.settings[0].tier == "db-custom-1-3840"
    error_message = "POSTGRES selects a PostgreSQL database version on the chosen tier."
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].availability_type == "ZONAL" && google_sql_database_instance.main.settings[0].backup_configuration[0].point_in_time_recovery_enabled
    error_message = "Without high_availability the PostgreSQL instance is zonal and keeps point-in-time recovery."
  }
}

run "managed_certificate" {
  command = plan

  variables {
    domains = ["shop.example.com"]
  }

  assert {
    condition     = length(google_compute_managed_ssl_certificate.domains) == 1 && length(google_compute_ssl_certificate.self_signed) == 0
    error_message = "domains replaces the self-signed certificate with a Google-managed one."
  }
}

run "inverted_node_bounds" {
  command = plan

  variables {
    compute_type = "mig"
    min_nodes    = 5
    max_nodes    = 2
  }

  assert {
    condition     = google_compute_region_autoscaler.app[0].autoscaling_policy[0].min_replicas == 5 && google_compute_region_autoscaler.app[0].autoscaling_policy[0].max_replicas == 5
    error_message = "A maximum below the minimum is raised to the minimum."
  }
}

run "inverted_node_bounds_on_gke" {
  command = plan

  variables {
    compute_type = "gke-standard"
    min_nodes    = 5
    max_nodes    = 2
  }

  assert {
    condition     = google_container_node_pool.standard[0].autoscaling[0].total_min_node_count == 5 && google_container_node_pool.standard[0].autoscaling[0].total_max_node_count == 5
    error_message = "A maximum below the minimum is raised to the minimum."
  }
}
