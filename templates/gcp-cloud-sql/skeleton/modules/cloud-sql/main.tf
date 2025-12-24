# =============================================================================
# GCP Cloud SQL - Module Main Configuration
# =============================================================================
# This module creates a Cloud SQL instance with database, user, and networking.
# Supports MySQL, PostgreSQL, and SQL Server with high availability options.
# =============================================================================

locals {
  instance_name = "${var.name}-${var.environment}"
  database_name = var.database_name != "" ? var.database_name : replace(var.name, "-", "_")

  # Determine database type from version
  is_postgres  = can(regex("^POSTGRES", var.database_version))
  is_mysql     = can(regex("^MYSQL", var.database_version))
  is_sqlserver = can(regex("^SQLSERVER", var.database_version))

  # Labels applied to all resources
  labels = merge(
    {
      environment = var.environment
      managed-by  = "terraform"
      project     = var.name
      owner       = replace(var.owner, "/[^a-z0-9-]/", "-")
    },
    var.labels
  )
}

# -----------------------------------------------------------------------------
# Random Password for Database User
# -----------------------------------------------------------------------------
resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# -----------------------------------------------------------------------------
# Private Service Connection (for Private IP)
# -----------------------------------------------------------------------------
resource "google_compute_global_address" "private_ip_range" {
  count = var.enable_private_ip ? 1 : 0

  name          = "${local.instance_name}-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.network_id

  labels = local.labels
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.enable_private_ip ? 1 : 0

  network                 = var.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range[0].name]
}

# -----------------------------------------------------------------------------
# Cloud SQL Instance
# -----------------------------------------------------------------------------
resource "google_sql_database_instance" "instance" {
  name                = local.instance_name
  database_version    = var.database_version
  region              = var.region
  deletion_protection = var.deletion_protection

  # Wait for private VPC connection if enabled
  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size
    disk_type         = var.disk_type
    disk_autoresize   = var.disk_autoresize

    # Activation policy
    activation_policy = var.activation_policy

    # User labels
    user_labels = local.labels

    # IP Configuration
    ip_configuration {
      ipv4_enabled    = var.enable_public_ip
      private_network = var.enable_private_ip ? var.network_id : null
      require_ssl     = var.require_ssl

      # Authorized networks for public IP
      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.cidr
        }
      }
    }

    # Backup Configuration
    backup_configuration {
      enabled                        = var.enable_backups
      start_time                     = var.backup_start_time
      location                       = var.backup_location
      point_in_time_recovery_enabled = local.is_postgres ? var.enable_point_in_time_recovery : false
      transaction_log_retention_days = var.transaction_log_retention_days

      backup_retention_settings {
        retained_backups = var.backup_retention_days
        retention_unit   = "COUNT"
      }
    }

    # Maintenance Window
    maintenance_window {
      day          = var.maintenance_window_day
      hour         = var.maintenance_window_hour
      update_track = var.maintenance_update_track
    }

    # Insights Config (Query Insights)
    insights_config {
      query_insights_enabled  = var.enable_query_insights
      query_string_length     = var.query_insights_string_length
      record_application_tags = var.query_insights_record_application_tags
      record_client_address   = var.query_insights_record_client_address
    }

    # Database Flags
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# Cloud SQL Database
# -----------------------------------------------------------------------------
resource "google_sql_database" "database" {
  name      = local.database_name
  instance  = google_sql_database_instance.instance.name
  charset   = local.is_postgres ? "UTF8" : (local.is_mysql ? "utf8mb4" : null)
  collation = local.is_postgres ? "en_US.UTF8" : (local.is_mysql ? "utf8mb4_general_ci" : null)

  deletion_policy = var.database_deletion_policy
}

# -----------------------------------------------------------------------------
# Cloud SQL User
# -----------------------------------------------------------------------------
resource "google_sql_user" "user" {
  name     = var.db_user_name
  instance = google_sql_database_instance.instance.name
  password = random_password.db_password.result

  # SQL Server requires host to be empty
  host = local.is_sqlserver ? null : (local.is_mysql ? "%" : null)

  deletion_policy = var.user_deletion_policy
}

# -----------------------------------------------------------------------------
# Secret Manager - Database Password
# -----------------------------------------------------------------------------
resource "google_secret_manager_secret" "db_password" {
  count = var.store_password_in_secret_manager ? 1 : 0

  secret_id = "${local.instance_name}-db-password"

  labels = local.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  count = var.store_password_in_secret_manager ? 1 : 0

  secret      = google_secret_manager_secret.db_password[0].id
  secret_data = random_password.db_password.result
}

# -----------------------------------------------------------------------------
# Cloud SQL SSL Certificates (Optional)
# -----------------------------------------------------------------------------
resource "google_sql_ssl_cert" "client_cert" {
  count = var.create_ssl_certificate ? 1 : 0

  common_name = "${local.instance_name}-client"
  instance    = google_sql_database_instance.instance.name
}
