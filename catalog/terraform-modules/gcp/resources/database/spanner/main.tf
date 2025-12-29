terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

locals {
  default_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
  labels = merge(local.default_labels, var.labels)
}

resource "google_spanner_instance" "this" {
  project      = var.project_id
  name         = var.instance_name
  display_name = var.display_name != null ? var.display_name : var.instance_name
  config       = "projects/${var.project_id}/instanceConfigs/${var.config}"

  num_nodes        = var.processing_units == null ? var.num_nodes : null
  processing_units = var.processing_units

  labels = local.labels
}

resource "google_spanner_database" "this" {
  for_each = { for db in var.databases : db.name => db }

  instance                 = google_spanner_instance.this.name
  name                     = each.value.name
  project                  = var.project_id
  ddl                      = each.value.ddl
  deletion_protection      = each.value.deletion_protection
  version_retention_period = each.value.version_retention_period
  enable_drop_protection   = each.value.enable_drop_protection
}

resource "google_spanner_instance_iam_member" "this" {
  for_each = {
    for binding in flatten([
      for b in var.instance_iam_bindings : [
        for member in b.members : {
          role   = b.role
          member = member
        }
      ]
    ]) : "${binding.role}-${binding.member}" => binding
  }

  project  = var.project_id
  instance = google_spanner_instance.this.name
  role     = each.value.role
  member   = each.value.member
}

resource "google_spanner_database_iam_member" "this" {
  for_each = {
    for binding in flatten([
      for b in var.database_iam_bindings : [
        for member in b.members : {
          database = b.database
          role     = b.role
          member   = member
        }
      ]
    ]) : "${binding.database}-${binding.role}-${binding.member}" => binding
  }

  project  = var.project_id
  instance = google_spanner_instance.this.name
  database = google_spanner_database.this[each.value.database].name
  role     = each.value.role
  member   = each.value.member
}
