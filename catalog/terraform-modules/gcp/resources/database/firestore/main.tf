terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = var.database_id
  location_id = var.location_id
  type        = var.type

  concurrency_mode                  = var.concurrency_mode
  app_engine_integration_mode       = var.app_engine_integration_mode
  point_in_time_recovery_enablement = var.point_in_time_recovery_enablement
  delete_protection_state           = var.delete_protection_state

  dynamic "cmek_config" {
    for_each = var.cmek_key_name != null ? [1] : []
    content {
      kms_key_name = var.cmek_key_name
    }
  }

  labels = merge(
    {
      project     = var.project_name
      environment = var.environment
    },
    var.labels
  )
}

resource "google_firestore_index" "indexes" {
  for_each = { for idx, index in var.indexes : "${index.collection}-${idx}" => index }

  project    = var.project_id
  database   = google_firestore_database.database.name
  collection = each.value.collection

  dynamic "fields" {
    for_each = each.value.fields
    content {
      field_path   = fields.value.field_path
      order        = lookup(fields.value, "order", null)
      array_config = lookup(fields.value, "array_config", null)
      vector_config {
        dimension = lookup(fields.value, "vector_dimension", null)
        flat {}
      }
    }
  }

  depends_on = [google_firestore_database.database]
}

resource "google_firestore_field" "fields" {
  for_each = { for idx, field in var.field_configs : "${field.collection}-${field.field}-${idx}" => field }

  project    = var.project_id
  database   = google_firestore_database.database.name
  collection = each.value.collection
  field      = each.value.field

  index_config {
    dynamic "indexes" {
      for_each = lookup(each.value, "indexes", [])
      content {
        order        = lookup(indexes.value, "order", null)
        array_config = lookup(indexes.value, "array_config", null)
        query_scope  = lookup(indexes.value, "query_scope", null)
      }
    }
  }

  dynamic "ttl_config" {
    for_each = lookup(each.value, "ttl_config", null) != null ? [each.value.ttl_config] : []
    content {
      state = lookup(ttl_config.value, "state", null)
    }
  }

  depends_on = [google_firestore_database.database]
}
