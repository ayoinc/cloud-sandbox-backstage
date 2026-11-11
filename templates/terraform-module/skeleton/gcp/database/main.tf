locals {
  # Resource names are limited to 63 characters and service account IDs to 30,
  # so the project name is shortened before the environment is appended.
  name_prefix = "${trimsuffix(substr(var.project_name, 0, 16), "-")}-${var.environment}"

  labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })

  # A null network selects the project's default network.
  network_id = coalesce(var.network_id, "projects/${var.project_id}/global/networks/default")

  # Without an existing private service access range the module reserves and
  # peers its own.
  create_private_service_access = var.private_ip_range == null
  private_ip_range              = local.create_private_service_access ? google_compute_global_address.private_service_access[0].name : var.private_ip_range

  is_postgres = startswith(var.database_version, "POSTGRES_")

  # Engine-specific hardening flags. Flags passed in database_flags win.
  default_database_flags = local.is_postgres ? {
    log_checkpoints    = "on"
    log_connections    = "on"
    log_disconnections = "on"
    log_lock_waits     = "on"
    log_temp_files     = "0"
    } : {
    local_infile = "off"
  }
  database_flags = merge(local.default_database_flags, var.database_flags)
}

resource "random_id" "instance" {
  byte_length = 4
}

# -----------------------------------------------------------------------------
# Private service access
# -----------------------------------------------------------------------------

resource "google_compute_global_address" "private_service_access" {
  count = local.create_private_service_access ? 1 : 0

  project       = var.project_id
  name          = "${local.name_prefix}-db-psa"
  description   = "Address range reserved for Cloud SQL and Memorystore"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_ip_prefix_length
  network       = local.network_id
  labels        = local.labels
}

resource "google_service_networking_connection" "private_service_access" {
  count = local.create_private_service_access ? 1 : 0

  network                 = local.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access[0].name]
}

# -----------------------------------------------------------------------------
# Cloud SQL
# -----------------------------------------------------------------------------

resource "google_sql_database_instance" "main" {
  project = var.project_id
  region  = var.region
  # Instance names stay reserved for a week after deletion, so the suffix
  # allows an immediate re-creation.
  name                = "${local.name_prefix}-${random_id.instance.hex}"
  database_version    = var.database_version
  encryption_key_name = var.kms_key_id
  deletion_protection = var.deletion_protection

  settings {
    tier                        = var.tier
    edition                     = var.edition
    availability_type           = var.high_availability ? "REGIONAL" : "ZONAL"
    disk_type                   = "PD_SSD"
    disk_size                   = var.disk_size_gb
    disk_autoresize             = true
    deletion_protection_enabled = var.deletion_protection
    user_labels                 = local.labels

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = local.network_id
      allocated_ip_range                            = local.private_ip_range
      enable_private_path_for_google_cloud_services = true
      ssl_mode                                      = "ENCRYPTED_ONLY"
    }

    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = var.backup_start_time
      point_in_time_recovery_enabled = local.is_postgres ? var.backup_enabled : null
      binary_log_enabled             = local.is_postgres ? null : var.backup_enabled
      transaction_log_retention_days = var.backup_enabled ? 7 : null

      backup_retention_settings {
        retained_backups = var.retained_backups
        retention_unit   = "COUNT"
      }
    }

    maintenance_window {
      day          = var.maintenance_window_day
      hour         = var.maintenance_window_hour
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = var.query_insights_enabled
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = false
    }

    dynamic "database_flags" {
      for_each = local.database_flags

      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }
  }

  depends_on = [google_service_networking_connection.private_service_access]
}

resource "google_sql_database" "main" {
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  name     = var.database_name
}

resource "random_password" "database" {
  length  = 32
  special = false
}

resource "google_sql_user" "main" {
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  name     = var.user_name
  password = random_password.database.result

  # PostgreSQL roles that own objects cannot be dropped, so the user is left
  # in place and disappears with the instance.
  deletion_policy = local.is_postgres ? "ABANDON" : null
}

resource "google_secret_manager_secret" "database" {
  project   = var.project_id
  secret_id = "${local.name_prefix}-db-credentials"
  labels    = local.labels

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "database" {
  secret = google_secret_manager_secret.database.id

  secret_data = jsonencode({
    engine          = local.is_postgres ? "postgres" : "mysql"
    host            = google_sql_database_instance.main.private_ip_address
    port            = local.is_postgres ? 5432 : 3306
    database        = google_sql_database.main.name
    username        = google_sql_user.main.name
    password        = random_password.database.result
    connection_name = google_sql_database_instance.main.connection_name
  })
}

# -----------------------------------------------------------------------------
# Memorystore for Redis
# -----------------------------------------------------------------------------

resource "google_redis_instance" "main" {
  count = var.enable_redis ? 1 : 0

  project        = var.project_id
  region         = var.region
  name           = "${local.name_prefix}-redis"
  display_name   = "${var.project_name} ${var.environment} cache"
  tier           = var.redis_tier
  memory_size_gb = var.redis_memory_size_gb
  redis_version  = var.redis_version
  labels         = local.labels

  authorized_network      = local.network_id
  connect_mode            = "PRIVATE_SERVICE_ACCESS"
  reserved_ip_range       = local.private_ip_range
  auth_enabled            = true
  transit_encryption_mode = "SERVER_AUTHENTICATION"
  customer_managed_key    = var.kms_key_id

  depends_on = [google_service_networking_connection.private_service_access]
}

resource "google_secret_manager_secret" "redis" {
  count = var.enable_redis ? 1 : 0

  project   = var.project_id
  secret_id = "${local.name_prefix}-redis-credentials"
  labels    = local.labels

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "redis" {
  count = var.enable_redis ? 1 : 0

  secret = google_secret_manager_secret.redis[0].id

  secret_data = jsonencode({
    host        = google_redis_instance.main[0].host
    port        = google_redis_instance.main[0].port
    auth_string = google_redis_instance.main[0].auth_string
    tls         = true
  })
}
