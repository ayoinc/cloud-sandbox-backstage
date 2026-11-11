locals {
  sql_backup_plan = var.enable_backup && local.cloud_sql
  gke_backup_plan = var.enable_backup && var.enable_kubernetes

  # Cluster backups are kept in the secondary region when disaster recovery
  # is enabled, so they survive the loss of the primary region.
  gke_backup_location = var.enable_disaster_recovery ? var.secondary_region : var.region
  gke_backup_key_id   = var.enable_disaster_recovery ? local.kms_secondary_key_id : local.kms_key_id
}

# Backups in the vault cannot be deleted before the enforced retention ends,
# not even by project owners.
resource "google_backup_dr_backup_vault" "this" {
  count = var.enable_backup ? 1 : 0

  project                                    = var.project_id
  location                                   = var.region
  backup_vault_id                            = "${var.name_prefix}-vault"
  description                                = "Backups of the ${var.name_prefix} ${var.environment} stack"
  backup_minimum_enforced_retention_duration = var.require_deletion_protection ? "604800s" : "86400s"
  access_restriction                         = "WITHIN_PROJECT"
  labels                                     = local.labels

  # Without deletion protection the vault can be destroyed together with
  # the stack once its backups have expired.
  ignore_inactive_datasources   = !var.require_deletion_protection
  ignore_backup_plan_references = !var.require_deletion_protection
  deletion_policy               = var.require_deletion_protection ? "PREVENT" : "DELETE"

  depends_on = [time_sleep.api_propagation]
}

# -----------------------------------------------------------------------------
# Cloud SQL
# -----------------------------------------------------------------------------

# The vault and the instance are in the same project, so the vault needs no
# extra role to read the instance.
resource "google_backup_dr_backup_plan" "database" {
  count = local.sql_backup_plan ? 1 : 0

  project            = var.project_id
  location           = var.region
  backup_plan_id     = "${var.name_prefix}-database"
  description        = "Daily backup of the database, kept for 35 days"
  resource_type      = "sqladmin.googleapis.com/Instance"
  backup_vault       = google_backup_dr_backup_vault.this[0].id
  log_retention_days = 7

  backup_rules {
    rule_id               = "daily"
    backup_retention_days = 35

    standard_schedule {
      recurrence_type = "DAILY"
      time_zone       = "UTC"

      backup_window {
        start_hour_of_day = 1
        end_hour_of_day   = 7
      }
    }
  }
}

resource "google_backup_dr_backup_plan_association" "database" {
  count = local.sql_backup_plan ? 1 : 0

  project                    = var.project_id
  location                   = var.region
  backup_plan_association_id = "${var.name_prefix}-database"
  backup_plan                = google_backup_dr_backup_plan.database[0].id
  resource                   = "projects/${var.project_id}/instances/${google_sql_database_instance.this[0].name}"
  resource_type              = "sqladmin.googleapis.com/Instance"

  # The Backup and DR service agent must be able to use the key of an
  # encrypted instance before a plan can be attached.
  depends_on = [time_sleep.kms_iam_propagation]
}

# -----------------------------------------------------------------------------
# GKE
# -----------------------------------------------------------------------------

# Daily backup of every namespace, including secrets and volume data.
resource "google_gke_backup_backup_plan" "this" {
  count = local.gke_backup_plan ? 1 : 0

  project     = var.project_id
  name        = "${var.name_prefix}-gke"
  description = "Daily backup of the cluster, kept for 35 days"
  location    = local.gke_backup_location
  cluster     = google_container_cluster.this[0].id
  labels      = local.labels

  retention_policy {
    backup_retain_days      = 35
    backup_delete_lock_days = var.require_deletion_protection ? 7 : 0
  }

  backup_schedule {
    cron_schedule = "0 3 * * *"
  }

  backup_config {
    all_namespaces      = true
    include_secrets     = true
    include_volume_data = true

    dynamic "encryption_key" {
      for_each = var.enable_kms ? [1] : []

      content {
        gcp_kms_encryption_key = local.gke_backup_key_id
      }
    }
  }

  depends_on = [time_sleep.kms_iam_propagation]
}
