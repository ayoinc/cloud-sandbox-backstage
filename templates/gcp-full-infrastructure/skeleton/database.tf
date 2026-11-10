# =============================================================================
# Database: Cloud SQL, Firestore and Memorystore Redis
# =============================================================================

locals {
  cloudsql_engine = (
    startswith(var.cloudsql_database_version, "POSTGRES") ? "postgres"
    : startswith(var.cloudsql_database_version, "MYSQL") ? "mysql"
    : "sqlserver"
  )

  # Logging and hardening flags per database engine.
  cloudsql_flags = {
    postgres = {
      "log_checkpoints"            = "on"
      "log_connections"            = "on"
      "log_disconnections"         = "on"
      "log_lock_waits"             = "on"
      "log_hostname"               = "on"
      "log_temp_files"             = "0"
      "log_min_messages"           = "warning"
      "log_min_error_statement"    = "error"
      "log_min_duration_statement" = "-1"
      "log_statement"              = "ddl"
      "cloudsql.enable_pgaudit"    = "on"
    }
    mysql = {
      "local_infile"       = "off"
      "skip_show_database" = "on"
    }
    sqlserver = {
      "cross db ownership chaining"       = "off"
      "contained database authentication" = "off"
      "remote access"                     = "off"
      "3625"                              = "on"
    }
  }
}

resource "random_password" "cloudsql" {
  count = var.enable_database ? 1 : 0

  length  = 32
  special = false
}

resource "google_sql_database_instance" "main" {
  # checkov:skip=CKV_GCP_6:Connections must be encrypted and the instance has no public address; set cloudsql_ssl_mode to also require client certificates
  count = var.enable_database ? 1 : 0

  # Instance names cannot be reused for a week after deletion.
  name                = "${local.name_prefix}-sql-${random_id.suffix.hex}"
  database_version    = var.cloudsql_database_version
  region              = var.region
  deletion_protection = local.is_production
  root_password       = local.cloudsql_engine == "sqlserver" ? random_password.cloudsql[0].result : null

  settings {
    tier              = var.cloudsql_tier
    availability_type = local.is_production ? "REGIONAL" : "ZONAL"
    disk_size         = var.cloudsql_disk_size
    disk_type         = "PD_SSD"
    disk_autoresize   = true
    user_labels       = local.labels

    # Private address only, reachable from the VPC network.
    ip_configuration {
      ipv4_enabled    = false
      private_network = local.network_id
      ssl_mode        = var.cloudsql_ssl_mode
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "02:00"
      binary_log_enabled             = local.cloudsql_engine == "mysql"
      point_in_time_recovery_enabled = local.cloudsql_engine == "postgres"

      backup_retention_settings {
        retained_backups = var.cloudsql_backup_retention
        retention_unit   = "COUNT"
      }
    }

    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }

    dynamic "database_flags" {
      for_each = local.cloudsql_flags[local.cloudsql_engine]
      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }
  }

  depends_on = [google_project_service.main, google_service_networking_connection.private_service_access]
}

resource "google_sql_database" "main" {
  count = var.enable_database ? 1 : 0

  name     = replace(var.project_name, "-", "_")
  instance = google_sql_database_instance.main[0].name
}

resource "google_sql_user" "main" {
  count = var.enable_database ? 1 : 0

  name     = "app"
  instance = google_sql_database_instance.main[0].name
  password = random_password.cloudsql[0].result
}

# The generated database password is kept in Secret Manager.
resource "google_secret_manager_secret" "cloudsql_password" {
  count = var.enable_database ? 1 : 0

  secret_id = "${local.name_prefix}-sql-password"
  labels    = local.labels

  replication {
    auto {}
  }

  depends_on = [google_project_service.main]
}

resource "google_secret_manager_secret_version" "cloudsql_password" {
  count = var.enable_database ? 1 : 0

  secret      = google_secret_manager_secret.cloudsql_password[0].id
  secret_data = random_password.cloudsql[0].result
}

resource "google_firestore_database" "main" {
  count = var.enable_database && var.enable_firestore ? 1 : 0

  name                              = local.name_prefix
  location_id                       = coalesce(var.firestore_location, var.region)
  type                              = "FIRESTORE_NATIVE"
  point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_ENABLED"
  delete_protection_state           = local.is_production ? "DELETE_PROTECTION_ENABLED" : "DELETE_PROTECTION_DISABLED"
  deletion_policy                   = "DELETE"

  depends_on = [google_project_service.main]
}

resource "google_redis_instance" "main" {
  count = var.enable_database && var.enable_redis ? 1 : 0

  name                    = "${local.name_prefix}-redis"
  region                  = var.region
  tier                    = local.is_production ? "STANDARD_HA" : "BASIC"
  memory_size_gb          = var.redis_memory_size_gb
  authorized_network      = local.network_id
  connect_mode            = "PRIVATE_SERVICE_ACCESS"
  auth_enabled            = true
  transit_encryption_mode = "SERVER_AUTHENTICATION"
  labels                  = local.labels

  depends_on = [google_project_service.main, google_service_networking_connection.private_service_access]
}
