# -----------------------------------------------------------------------------
# Data tier: Cloud SQL with a private address only. The password of the
# application's database user is generated and kept in Secret Manager.
# -----------------------------------------------------------------------------

locals {
  is_postgres = var.database_engine == "POSTGRES"

  default_database_versions = {
    POSTGRES = "POSTGRES_16"
    MYSQL    = "MYSQL_8_0"
  }

  database_version = coalesce(var.database_version, local.default_database_versions[var.database_engine])

  database_password_secret_id = "${local.name_prefix}-db-password"
}

# Cloud SQL keeps the name of a deleted instance reserved for a week, so the
# name carries a suffix that changes when the instance is replaced.
resource "random_id" "database" {
  byte_length = 3

  keepers = {
    engine = var.database_engine
  }
}

resource "google_sql_database_instance" "main" {
  name             = "${local.name_prefix}-db-${random_id.database.hex}"
  region           = var.region
  database_version = local.database_version

  deletion_protection = local.is_production

  settings {
    tier              = var.database_tier
    edition           = "ENTERPRISE"
    availability_type = var.high_availability ? "REGIONAL" : "ZONAL"

    disk_type       = "PD_SSD"
    disk_size       = var.database_disk_size
    disk_autoresize = true

    deletion_protection_enabled = local.is_production
    user_labels                 = local.common_labels

    ip_configuration {
      ipv4_enabled    = false
      private_network = module.vpc.network_id
      ssl_mode        = "ENCRYPTED_ONLY"
    }

    # A standby instance needs point-in-time recovery: write-ahead logs on
    # PostgreSQL, binary logs on MySQL.
    backup_configuration {
      enabled                        = true
      start_time                     = "02:00"
      point_in_time_recovery_enabled = local.is_postgres
      binary_log_enabled             = !local.is_postgres
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = local.is_production ? 30 : 7
      }
    }

    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled = true
    }
  }

  # The private address comes from the peering range of the VPC.
  depends_on = [google_service_networking_connection.managed_services]
}

resource "google_sql_database" "app" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name
}

resource "random_password" "database" {
  length  = 32
  special = false
}

resource "google_sql_user" "app" {
  name     = var.database_username
  instance = google_sql_database_instance.main.name
  password = random_password.database.result

  # MySQL users are bound to a client host; PostgreSQL users are not.
  host = local.is_postgres ? null : "%"
}

module "database_password" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/security/secret-manager?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  project_id   = var.gcp_project_id
  environment  = var.environment

  secrets = [
    {
      secret_id        = local.database_password_secret_id
      replication_type = "automatic"
      iam_bindings = [
        {
          role   = "roles/secretmanager.secretAccessor"
          member = "serviceAccount:${local.name_prefix}-app@${var.gcp_project_id}.iam.gserviceaccount.com"
        },
      ]
    },
  ]

  # The binding names the application's service account by its address, so the
  # account has to exist first.
  depends_on = [
    google_project_service.required,
    module.app_service_account,
  ]
}

# The secret module decides which versions to create from the secret values
# themselves, which a generated password cannot be used for, so the version is
# written here.
resource "google_secret_manager_secret_version" "database_password" {
  secret      = module.database_password.secret_ids[local.database_password_secret_id]
  secret_data = random_password.database.result
}
