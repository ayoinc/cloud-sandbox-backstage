mock_provider "google" {}
mock_provider "random" {}

variables {
  project_name = "acme-platform"
  environment  = "dev"
  project_id   = "acme-platform-dev"
  region       = "us-central1"
}

run "defaults" {
  command = plan

  assert {
    condition     = google_sql_database_instance.main.database_version == "POSTGRES_17"
    error_message = "The default engine must be PostgreSQL 17."
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].edition == "ENTERPRISE" && google_sql_database_instance.main.settings[0].tier == "db-custom-1-3840"
    error_message = "The default edition and tier must match."
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].availability_type == "ZONAL"
    error_message = "The instance must be zonal by default."
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].ip_configuration[0].ipv4_enabled == false
    error_message = "The instance must not have a public IP address."
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].ip_configuration[0].private_network == "projects/acme-platform-dev/global/networks/default"
    error_message = "Without a network the instance must attach to the default network."
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].ip_configuration[0].ssl_mode == "ENCRYPTED_ONLY"
    error_message = "Only encrypted connections may be accepted."
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].ip_configuration[0].allocated_ip_range == "acme-platform-dev-db-psa"
    error_message = "The instance must allocate from the range reserved by the module."
  }

  assert {
    condition     = length(google_compute_global_address.private_service_access) == 1 && length(google_service_networking_connection.private_service_access) == 1
    error_message = "The module must set up private service access when no range is given."
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].backup_configuration[0].enabled == true && google_sql_database_instance.main.settings[0].backup_configuration[0].point_in_time_recovery_enabled == true
    error_message = "Backups and point-in-time recovery must be on by default."
  }

  assert {
    condition     = length(google_sql_database_instance.main.settings[0].database_flags) == 5
    error_message = "The five PostgreSQL logging flags must be set by default."
  }

  assert {
    condition     = google_sql_database_instance.main.deletion_protection == true
    error_message = "Deletion protection must be on by default."
  }

  assert {
    condition     = google_sql_database.main.name == "app" && google_sql_user.main.name == "app" && google_sql_user.main.deletion_policy == "ABANDON"
    error_message = "The default database and user must be created."
  }

  assert {
    condition     = google_secret_manager_secret.database.secret_id == "acme-platform-dev-db-credentials"
    error_message = "The credentials secret must be named after the project and environment."
  }

  assert {
    condition     = length(google_redis_instance.main) == 0 && output.redis_host == null
    error_message = "Redis must be off by default."
  }
}

run "existing_network_and_range" {
  command = plan

  variables {
    network_id       = "projects/acme-platform-dev/global/networks/acme-platform-dev-vpc"
    private_ip_range = "acme-platform-dev-psa"
  }

  assert {
    condition     = length(google_compute_global_address.private_service_access) == 0 && length(google_service_networking_connection.private_service_access) == 0
    error_message = "An existing range must not be reserved or peered again."
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].ip_configuration[0].private_network == "projects/acme-platform-dev/global/networks/acme-platform-dev-vpc"
    error_message = "The instance must attach to the given network."
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].ip_configuration[0].allocated_ip_range == "acme-platform-dev-psa"
    error_message = "The instance must allocate from the given range."
  }
}

run "mysql" {
  command = plan

  variables {
    database_version = "MYSQL_8_4"
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].backup_configuration[0].binary_log_enabled == true
    error_message = "MySQL point-in-time recovery needs binary logging."
  }

  assert {
    condition     = one(google_sql_database_instance.main.settings[0].database_flags[*].name) == "local_infile"
    error_message = "MySQL must disable local_infile by default."
  }
}

run "all_features" {
  command = plan

  variables {
    high_availability    = true
    tier                 = "db-custom-2-7680"
    kms_key_id           = "projects/acme-platform-dev/locations/us-central1/keyRings/acme/cryptoKeys/acme-key"
    database_flags       = { max_connections = "200" }
    deletion_protection  = false
    enable_redis         = true
    redis_tier           = "STANDARD_HA"
    redis_memory_size_gb = 2
    redis_version        = "REDIS_7_2"
  }

  assert {
    condition     = google_sql_database_instance.main.settings[0].availability_type == "REGIONAL"
    error_message = "High availability must make the instance regional."
  }

  assert {
    condition     = google_sql_database_instance.main.encryption_key_name == "projects/acme-platform-dev/locations/us-central1/keyRings/acme/cryptoKeys/acme-key"
    error_message = "The instance must be encrypted with the given key."
  }

  assert {
    condition     = length(google_sql_database_instance.main.settings[0].database_flags) == 6
    error_message = "Custom flags must be merged with the defaults."
  }

  assert {
    condition     = google_redis_instance.main[0].tier == "STANDARD_HA" && google_redis_instance.main[0].memory_size_gb == 2
    error_message = "Redis must use the configured tier and size."
  }

  assert {
    condition     = google_redis_instance.main[0].auth_enabled == true && google_redis_instance.main[0].transit_encryption_mode == "SERVER_AUTHENTICATION"
    error_message = "Redis must require AUTH and TLS."
  }

  assert {
    condition     = google_redis_instance.main[0].connect_mode == "PRIVATE_SERVICE_ACCESS" && google_redis_instance.main[0].reserved_ip_range == "acme-platform-dev-db-psa"
    error_message = "Redis must use the private service access range."
  }

  assert {
    condition     = google_secret_manager_secret.redis[0].secret_id == "acme-platform-dev-redis-credentials"
    error_message = "The Redis credentials secret must be created."
  }
}

run "rejects_unsupported_engine" {
  command = plan

  variables {
    database_version = "POSTGRES_11"
  }

  expect_failures = [var.database_version]
}
