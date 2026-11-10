# Every run applies against mocked providers, so no resources are created and
# no credentials are needed. Run with: terraform test

mock_provider "google" {}

variables {
  project_name   = "demo"
  component_name = "demo-infra"
  description    = "Test stack"
  project_id     = "test-project-123"
  environment    = "dev"
  region         = "us-central1"

  labels = {
    managedBy = "backstage"
  }

  network_cidr = "10.0.0.0/16"
  subnets = [
    { name = "public", cidr = "10.0.1.0/24", region = "us-central1" },
    { name = "private", cidr = "10.0.10.0/24", region = "us-east1" },
  ]

  machine_type   = "e2-medium"
  boot_disk_size = 50
  boot_disk_type = "pd-balanced"

  gke_version            = "1.35"
  gke_node_machine_type  = "e2-medium"
  gke_node_locations     = ["us-central1-a", "us-central1-b"]
  gke_initial_node_count = 1
  gke_min_node_count     = 1
  gke_max_node_count     = 3

  storage_class     = "STANDARD"
  enable_versioning = true

  cloudsql_database_version = "POSTGRES_15"
  cloudsql_tier             = "db-custom-1-3840"
  cloudsql_disk_size        = 20
  cloudsql_backup_retention = 7
}

run "everything_enabled" {
  command = apply

  assert {
    condition     = output.name_prefix == "demo-dev"
    error_message = "Resource names should start with {project_name}-{environment}"
  }

  assert {
    condition     = length(google_compute_subnetwork.main) == 2
    error_message = "One subnet per entry of var.subnets should be created"
  }

  assert {
    condition     = length(google_compute_router_nat.main) == 2
    error_message = "Each region with a subnet should have a Cloud NAT"
  }

  assert {
    condition     = google_compute_subnetwork.gke[0].ip_cidr_range == "10.0.240.0/20"
    error_message = "The GKE subnet should be the last /20 of the network range"
  }

  assert {
    condition     = google_storage_bucket.data[0].encryption[0].default_kms_key_name == google_kms_crypto_key.main[0].id
    error_message = "The data bucket should be encrypted with the Cloud KMS key"
  }

  assert {
    condition     = google_sql_database_instance.main[0].settings[0].ip_configuration[0].ipv4_enabled == false
    error_message = "Cloud SQL should not have a public address"
  }

  assert {
    condition     = length(google_firestore_database.main) == 1 && length(google_redis_instance.main) == 1 && length(google_filestore_instance.main) == 1
    error_message = "Firestore, Redis and Filestore should be created when enabled"
  }

  assert {
    condition     = google_container_cluster.main[0].resource_labels["managedby"] == "backstage"
    error_message = "Label keys should be normalised to lowercase"
  }
}

run "everything_disabled" {
  command = apply

  variables {
    enable_networking = false
    enable_compute    = false
    enable_containers = false
    enable_storage    = false
    enable_database   = false
    enable_security   = false
    enable_monitoring = false
    enable_analytics  = false
    enable_ai_ml      = false
    enable_serverless = false
  }

  assert {
    condition     = length(output.enabled_services) == 2
    error_message = "Only the base APIs should be enabled when every category is off"
  }

  assert {
    condition     = output.gke_cluster_name == null && output.data_bucket == null && output.cloudsql_instance_name == null
    error_message = "No category resources should be created when every category is off"
  }

  assert {
    condition     = output.network_id == "projects/test-project-123/global/networks/default"
    error_message = "The existing network should be used when networking is off"
  }
}

run "database_without_optional_stores" {
  command = apply

  variables {
    enable_firestore = false
    enable_redis     = false
    enable_filestore = false
  }

  assert {
    condition     = length(google_firestore_database.main) == 0 && length(google_redis_instance.main) == 0 && length(google_filestore_instance.main) == 0
    error_message = "Firestore, Redis and Filestore should not be created when their switches are off"
  }

  assert {
    condition     = length(google_sql_database_instance.main) == 1
    error_message = "Cloud SQL should still be created"
  }
}

run "storage_without_security" {
  command = apply

  variables {
    enable_security  = false
    enable_analytics = true
  }

  assert {
    condition     = length(google_storage_bucket.data[0].encryption) == 0
    error_message = "Buckets should use Google-managed encryption when the security category is off"
  }

  assert {
    condition     = output.kms_key_id == null
    error_message = "No Cloud KMS key should be created when the security category is off"
  }
}

run "mysql_engine" {
  command = apply

  variables {
    cloudsql_database_version = "MYSQL_8_0"
  }

  assert {
    condition     = google_sql_database_instance.main[0].settings[0].backup_configuration[0].binary_log_enabled == true
    error_message = "MySQL instances should enable binary logging for point-in-time recovery"
  }
}

run "production_is_protected" {
  command = apply

  variables {
    environment = "prod"
  }

  assert {
    condition     = google_sql_database_instance.main[0].deletion_protection == true
    error_message = "Production Cloud SQL instances should have deletion protection"
  }

  assert {
    condition     = google_storage_bucket.data[0].force_destroy == false
    error_message = "Production buckets should not be force destroyed"
  }
}

run "network_range_too_small" {
  command = plan

  variables {
    network_cidr = "10.0.0.0/24"
  }

  expect_failures = [var.network_cidr]
}
