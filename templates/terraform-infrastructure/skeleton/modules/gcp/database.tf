locals {
  mysql       = var.database_type == "mysql"
  sql_version = coalesce(var.database_version, local.mysql ? "MYSQL_8_4" : "POSTGRES_17")
  sql_port    = local.mysql ? 3306 : 5432

  # Dedicated-core machines: 4 vCPU/15 GB in production, 2 vCPU/7.5 GB
  # elsewhere, 1 vCPU/3.75 GB when costs are optimized outside production.
  sql_tier = (
    local.is_production ? "db-custom-4-15360" :
    var.enable_cost_optimization ? "db-custom-1-3840" : "db-custom-2-7680"
  )

  # Disaster recovery always stores the backups in the secondary region. A
  # standby replica there is added in production only, because it costs as
  # much as the primary instance.
  sql_replica = local.cloud_sql && var.enable_disaster_recovery && local.is_production

  sql_engine_flags = {
    mysql = {
      local_infile   = "off"
      slow_query_log = "on"
    }
    postgresql = {
      "cloudsql.iam_authentication" = "on"
      log_checkpoints               = "on"
      log_connections               = "on"
      log_disconnections            = "on"
      log_lock_waits                = "on"
      log_temp_files                = "0"
    }
  }
  sql_flags = local.sql_engine_flags[local.mysql ? "mysql" : "postgresql"]

  sql_instance_name = "${var.name_prefix}-${local.mysql ? "mysql" : "pg"}-${local.suffix}"
  redis_name        = "${var.name_prefix}-redis"

  database_name     = replace(var.name_prefix, "-", "_")
  database_username = "app_admin"

  # Reserved range the managed data stores are placed in.
  private_services_range_name = one(google_compute_global_address.private_services[*].name)

  redis_memory_gb = local.is_production ? 5 : var.enable_cost_optimization ? 1 : 2

  database_secret = var.enable_database && var.enable_secrets_manager

  # Secrets are stored in the stack's own regions, not replicated worldwide.
  secret_locations = {
    for name, location in { primary = var.region, secondary = var.secondary_region } :
    name => location
    if name == "primary" || var.enable_disaster_recovery
  }
}

# -----------------------------------------------------------------------------
# Cloud SQL (postgresql, mysql)
# -----------------------------------------------------------------------------

resource "google_sql_database_instance" "this" {
  count = local.cloud_sql ? 1 : 0

  project             = var.project_id
  name                = local.sql_instance_name
  region              = var.region
  database_version    = local.sql_version
  encryption_key_name = local.kms_key_id
  deletion_protection = var.require_deletion_protection

  settings {
    tier                        = local.sql_tier
    edition                     = "ENTERPRISE"
    availability_type           = local.is_production ? "REGIONAL" : "ZONAL"
    disk_type                   = "PD_SSD"
    disk_size                   = 20
    disk_autoresize             = true
    deletion_protection_enabled = var.require_deletion_protection
    retain_backups_on_delete    = var.enable_backup
    user_labels                 = local.labels

    # Private address only, and clients must use TLS.
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = local.network_id
      allocated_ip_range                            = local.private_services_range_name
      ssl_mode                                      = "ENCRYPTED_ONLY"
      enable_private_path_for_google_cloud_services = true
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "01:00"
      location                       = var.enable_disaster_recovery ? var.secondary_region : null
      point_in_time_recovery_enabled = local.mysql ? null : true
      binary_log_enabled             = local.mysql ? true : null
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = var.enable_backup ? 35 : 7
        retention_unit   = "COUNT"
      }
    }

    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled = var.enable_monitoring
    }

    dynamic "database_flags" {
      for_each = local.sql_flags

      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }
  }

  depends_on = [
    time_sleep.api_propagation,
    time_sleep.kms_iam_propagation,
    google_service_networking_connection.private_services,
  ]

  lifecycle {
    precondition {
      condition     = local.network_available
      error_message = local.network_required_message
    }
  }
}

resource "google_sql_database_instance" "replica" {
  count = local.sql_replica ? 1 : 0

  project              = var.project_id
  name                 = "${var.name_prefix}-${local.mysql ? "mysql" : "pg"}-dr-${local.suffix}"
  region               = var.secondary_region
  database_version     = local.sql_version
  master_instance_name = google_sql_database_instance.this[0].name
  encryption_key_name  = local.kms_secondary_key_id
  deletion_protection  = var.require_deletion_protection

  settings {
    tier                        = local.sql_tier
    edition                     = "ENTERPRISE"
    availability_type           = "ZONAL"
    disk_type                   = "PD_SSD"
    disk_autoresize             = true
    deletion_protection_enabled = var.require_deletion_protection
    user_labels                 = local.labels

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = local.network_id
      allocated_ip_range                            = local.private_services_range_name
      ssl_mode                                      = "ENCRYPTED_ONLY"
      enable_private_path_for_google_cloud_services = true
    }

    insights_config {
      query_insights_enabled = var.enable_monitoring
    }

    dynamic "database_flags" {
      for_each = local.sql_flags

      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }
  }

  depends_on = [time_sleep.kms_iam_propagation]
}

resource "google_sql_database" "this" {
  count = local.cloud_sql ? 1 : 0

  project  = var.project_id
  name     = local.database_name
  instance = google_sql_database_instance.this[0].name

  # PostgreSQL refuses to drop a database or role that still owns objects;
  # both disappear with the instance instead.
  deletion_policy = local.mysql ? "DELETE" : "ABANDON"
}

resource "random_password" "database" {
  count = local.cloud_sql ? 1 : 0

  length  = 32
  special = false
}

resource "google_sql_user" "admin" {
  count = local.cloud_sql ? 1 : 0

  project         = var.project_id
  name            = local.database_username
  instance        = google_sql_database_instance.this[0].name
  host            = local.mysql ? "%" : null
  password        = random_password.database[0].result
  deletion_policy = local.mysql ? "DELETE" : "ABANDON"
}

# -----------------------------------------------------------------------------
# Memorystore for Redis (redis)
# -----------------------------------------------------------------------------

resource "google_redis_instance" "this" {
  count = local.redis ? 1 : 0

  project        = var.project_id
  name           = local.redis_name
  display_name   = "Redis of the ${var.name_prefix} ${var.environment} stack"
  region         = var.region
  tier           = local.is_production ? "STANDARD_HA" : "BASIC"
  memory_size_gb = local.redis_memory_gb
  labels         = local.labels

  # Private address only; clients authenticate and use TLS.
  connect_mode            = "PRIVATE_SERVICE_ACCESS"
  authorized_network      = local.network_id
  reserved_ip_range       = local.private_services_range_name
  auth_enabled            = true
  transit_encryption_mode = "SERVER_AUTHENTICATION"
  customer_managed_key    = local.kms_key_id
  deletion_protection     = var.require_deletion_protection

  # With backups enabled the data set is saved to disk once a day.
  persistence_config {
    persistence_mode    = var.enable_backup ? "RDB" : "DISABLED"
    rdb_snapshot_period = var.enable_backup ? "TWENTY_FOUR_HOURS" : null
  }

  maintenance_policy {
    weekly_maintenance_window {
      day = "SUNDAY"

      start_time {
        hours   = 3
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }

  depends_on = [
    time_sleep.api_propagation,
    time_sleep.kms_iam_propagation,
    google_service_networking_connection.private_services,
  ]

  lifecycle {
    precondition {
      condition     = local.network_available
      error_message = local.network_required_message
    }
  }
}

# -----------------------------------------------------------------------------
# Database credentials in Secret Manager
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "database" {
  count = local.database_secret ? 1 : 0

  project             = var.project_id
  secret_id           = "${var.name_prefix}-database-credentials"
  labels              = local.labels
  deletion_protection = var.require_deletion_protection

  replication {
    user_managed {
      dynamic "replicas" {
        for_each = local.secret_locations

        content {
          location = replicas.value

          dynamic "customer_managed_encryption" {
            for_each = var.enable_kms ? [1] : []

            content {
              kms_key_name = google_kms_crypto_key.this[replicas.key].id
            }
          }
        }
      }
    }
  }

  depends_on = [time_sleep.api_propagation, time_sleep.kms_iam_propagation]
}

resource "google_secret_manager_secret_version" "database" {
  count = local.database_secret ? 1 : 0

  secret = google_secret_manager_secret.database[0].id

  secret_data = local.cloud_sql ? jsonencode({
    engine   = var.database_type
    host     = google_sql_database_instance.this[0].private_ip_address
    port     = local.sql_port
    database = google_sql_database.this[0].name
    username = google_sql_user.admin[0].name
    password = random_password.database[0].result
    }) : jsonencode({
    engine   = "redis"
    host     = google_redis_instance.this[0].host
    port     = google_redis_instance.this[0].port
    password = google_redis_instance.this[0].auth_string
    tls      = true
  })
}
