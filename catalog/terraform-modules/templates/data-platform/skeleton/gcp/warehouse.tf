# -----------------------------------------------------------------------------
# Data warehouse: BigQuery datasets and an Enterprise edition reservation.
# -----------------------------------------------------------------------------

locals {
  # zone: the Dataplex zone the dataset is catalogued in.
  warehouse_datasets = {
    staging = {
      description = "Data loaded from the lake and from streams before it is modelled"
      zone        = "raw"
    }
    warehouse = {
      description = "Modelled, historised data"
      zone        = "processed"
    }
    marts = {
      description = "Tables shaped for reports, dashboards and models"
      zone        = "curated"
    }
  }

  # Largest number of slots the reservation scales to. The portal presents the sizes
  # as 2, 4 and 8 nodes; one node corresponds to 50 slots.
  warehouse_max_slots = { small = 100, medium = 200, large = 400 }

  # Memory of the BI Engine reservation in GB.
  bi_engine_memory_gb = { small = 1, medium = 2, large = 4 }
}

resource "google_bigquery_dataset" "this" {
  for_each = var.enable_data_warehouse ? local.warehouse_datasets : {}

  dataset_id    = "${local.dataset_prefix}_${each.key}"
  friendly_name = "${var.project_name} ${var.environment} ${each.key}"
  description   = each.value.description
  location      = var.region

  delete_contents_on_destroy = !local.is_production

  dynamic "default_encryption_configuration" {
    for_each = var.enable_encryption ? [1] : []

    content {
      kms_key_name = local.kms_key_ids["bigquery"]
    }
  }

  depends_on = [google_project_service.apis, google_kms_crypto_key_iam_member.service_agent]
}

# Enterprise is the smallest edition that can query tables with customer-managed
# keys and policy tags and that BI Engine accelerates.
resource "google_bigquery_reservation" "warehouse" {
  count = var.enable_data_warehouse ? 1 : 0

  name              = "${local.name_prefix}-warehouse"
  location          = var.region
  edition           = "ENTERPRISE"
  slot_capacity     = var.warehouse_baseline_slots
  ignore_idle_slots = false

  autoscale {
    max_slots = local.warehouse_max_slots[var.warehouse_size]
  }

  depends_on = [google_project_service.apis]
}

resource "google_bigquery_reservation_assignment" "warehouse" {
  count = var.enable_data_warehouse && var.assign_project_to_reservation ? 1 : 0

  assignee    = "projects/${var.gcp_project_id}"
  job_type    = "QUERY"
  reservation = google_bigquery_reservation.warehouse[0].id
}
