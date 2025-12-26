# -----------------------------------------------------------------------------
# GCP Database Module - Main Resources
# Cloud SQL Instance with Private IP and Optional Memorystore Redis
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  name_prefix   = "${var.project_id}-${var.environment}"
  instance_name = "${local.name_prefix}-sql-${random_id.instance_suffix.hex}"

  # Determine database port based on version
  db_port = startswith(var.database_version, "POSTGRES") ? 5432 : 3306

  # Determine database flags based on version
  is_postgres = startswith(var.database_version, "POSTGRES")
  is_mysql    = startswith(var.database_version, "MYSQL")

  default_labels = {
    environment = var.environment
    managed_by  = "terraform"
    module      = "database"
  }

  labels = merge(local.default_labels, var.labels)
}

# -----------------------------------------------------------------------------
# Random Resources
# -----------------------------------------------------------------------------

resource "random_password" "database" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
  min_lower        = 4
  min_upper        = 4
  min_numeric      = 4
  min_special      = 4
}

resource "random_id" "instance_suffix" {
  byte_length = 4
}

# -----------------------------------------------------------------------------
# Private Service Access (VPC Peering for Private IP)
# -----------------------------------------------------------------------------

resource "google_compute_global_address" "private_ip_range" {
  count = var.enable_private_ip ? 1 : 0

  name          = "${local.name_prefix}-sql-private-ip-range"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_ip_prefix_length
  network       = var.network_self_link

  labels = local.labels
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.enable_private_ip ? 1 : 0

  network                 = var.network_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range[0].name]

  deletion_policy = "ABANDON"
}

# -----------------------------------------------------------------------------
# Cloud SQL Instance
# -----------------------------------------------------------------------------

resource "google_sql_database_instance" "main" {
  name             = local.instance_name
  project          = var.project_id
  region           = var.region
  database_version = var.database_version

  # Deletion protection
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    edition           = var.edition
    availability_type = var.availability_type
    disk_size         = var.disk_size
    disk_type         = var.disk_type
    disk_autoresize   = var.disk_autoresize

    # User labels
    user_labels = local.labels

    # Activation policy
    activation_policy = var.activation_policy

    # Backup configuration
    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = var.backup_start_time
      location                       = var.backup_location
      point_in_time_recovery_enabled = var.point_in_time_recovery_enabled
      transaction_log_retention_days = var.transaction_log_retention_days

      backup_retention_settings {
        retained_backups = var.retained_backups
        retention_unit   = "COUNT"
      }
    }

    # IP configuration
    ip_configuration {
      ipv4_enabled                                  = var.enable_public_ip
      private_network                               = var.enable_private_ip ? var.network_self_link : null
      ssl_mode                                      = var.require_ssl ? "ENCRYPTED_ONLY" : "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
      enable_private_path_for_google_cloud_services = var.enable_private_path_for_google_cloud_services

      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.cidr
        }
      }
    }

    # Maintenance window
    maintenance_window {
      day          = var.maintenance_window_day
      hour         = var.maintenance_window_hour
      update_track = var.maintenance_window_update_track
    }

    # Query insights (Performance insights)
    insights_config {
      query_insights_enabled  = var.query_insights_enabled
      query_string_length     = var.query_string_length
      record_application_tags = var.record_application_tags
      record_client_address   = var.record_client_address
      query_plans_per_minute  = var.query_plans_per_minute
    }

    # Database flags
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    # Deny maintenance period (optional)
    dynamic "deny_maintenance_period" {
      for_each = var.deny_maintenance_period != null ? [var.deny_maintenance_period] : []
      content {
        start_date = deny_maintenance_period.value.start_date
        end_date   = deny_maintenance_period.value.end_date
        time       = deny_maintenance_period.value.time
      }
    }
  }

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]

  lifecycle {
    ignore_changes = [
      settings[0].disk_size,
    ]
  }
}

# -----------------------------------------------------------------------------
# Cloud SQL Database
# -----------------------------------------------------------------------------

resource "google_sql_database" "main" {
  name      = var.database_name
  project   = var.project_id
  instance  = google_sql_database_instance.main.name
  charset   = local.is_postgres ? "UTF8" : "utf8mb4"
  collation = local.is_postgres ? "en_US.UTF8" : "utf8mb4_general_ci"

  deletion_policy = var.database_deletion_policy

  depends_on = [google_sql_database_instance.main]
}

# -----------------------------------------------------------------------------
# Cloud SQL User
# -----------------------------------------------------------------------------

resource "google_sql_user" "main" {
  name     = var.user_name
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  password = random_password.database.result

  # For PostgreSQL, specify the type
  type = local.is_postgres ? "BUILT_IN" : null

  deletion_policy = var.user_deletion_policy

  depends_on = [google_sql_database_instance.main]
}

# -----------------------------------------------------------------------------
# Secret Manager - Store Database Credentials
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "db_credentials" {
  secret_id = "${local.name_prefix}-db-credentials"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = local.labels
}

resource "google_secret_manager_secret_version" "db_credentials" {
  secret = google_secret_manager_secret.db_credentials.id
  secret_data = jsonencode({
    username          = google_sql_user.main.name
    password          = random_password.database.result
    database          = google_sql_database.main.name
    host              = var.enable_private_ip ? google_sql_database_instance.main.private_ip_address : google_sql_database_instance.main.public_ip_address
    port              = local.db_port
    connection_name   = google_sql_database_instance.main.connection_name
    connection_string = local.is_postgres ? "postgresql://${google_sql_user.main.name}:${random_password.database.result}@${var.enable_private_ip ? google_sql_database_instance.main.private_ip_address : google_sql_database_instance.main.public_ip_address}:${local.db_port}/${google_sql_database.main.name}?sslmode=require" : "mysql://${google_sql_user.main.name}:${random_password.database.result}@${var.enable_private_ip ? google_sql_database_instance.main.private_ip_address : google_sql_database_instance.main.public_ip_address}:${local.db_port}/${google_sql_database.main.name}"
  })

  depends_on = [
    google_sql_database_instance.main,
    google_sql_database.main,
    google_sql_user.main
  ]
}

# -----------------------------------------------------------------------------
# Memorystore Redis (Optional)
# -----------------------------------------------------------------------------

resource "google_redis_instance" "main" {
  count = var.enable_redis ? 1 : 0

  name           = "${local.name_prefix}-redis"
  project        = var.project_id
  region         = var.region
  tier           = var.redis_tier
  memory_size_gb = var.redis_memory_size_gb
  redis_version  = var.redis_version

  # Network configuration
  authorized_network = var.network_self_link
  connect_mode       = var.redis_connect_mode

  # Reserved IP range for Redis
  reserved_ip_range = var.redis_reserved_ip_range

  # Display name
  display_name = "${local.name_prefix}-redis"

  # Redis configuration
  redis_configs = var.redis_configs

  # Auth
  auth_enabled = var.redis_auth_enabled

  # Transit encryption
  transit_encryption_mode = var.redis_transit_encryption_mode

  # Maintenance policy
  dynamic "maintenance_policy" {
    for_each = var.redis_maintenance_policy != null ? [var.redis_maintenance_policy] : []
    content {
      weekly_maintenance_window {
        day = maintenance_policy.value.day
        start_time {
          hours   = maintenance_policy.value.start_hour
          minutes = maintenance_policy.value.start_minute
        }
      }
    }
  }

  # Persistence configuration (for Standard tier)
  dynamic "persistence_config" {
    for_each = var.redis_tier == "STANDARD_HA" && var.redis_persistence_mode != null ? [1] : []
    content {
      persistence_mode    = var.redis_persistence_mode
      rdb_snapshot_period = var.redis_rdb_snapshot_period
    }
  }

  labels = local.labels

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# Secret Manager - Store Redis Credentials (if enabled)
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "redis_credentials" {
  count = var.enable_redis ? 1 : 0

  secret_id = "${local.name_prefix}-redis-credentials"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = local.labels
}

resource "google_secret_manager_secret_version" "redis_credentials" {
  count = var.enable_redis ? 1 : 0

  secret = google_secret_manager_secret.redis_credentials[0].id
  secret_data = jsonencode({
    host                = google_redis_instance.main[0].host
    port                = google_redis_instance.main[0].port
    auth_string         = var.redis_auth_enabled ? google_redis_instance.main[0].auth_string : null
    current_location_id = google_redis_instance.main[0].current_location_id
    connection_string   = var.redis_auth_enabled ? "redis://:${google_redis_instance.main[0].auth_string}@${google_redis_instance.main[0].host}:${google_redis_instance.main[0].port}" : "redis://${google_redis_instance.main[0].host}:${google_redis_instance.main[0].port}"
  })

  depends_on = [google_redis_instance.main]
}
