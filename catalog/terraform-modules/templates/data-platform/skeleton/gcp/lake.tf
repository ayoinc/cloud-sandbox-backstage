# -----------------------------------------------------------------------------
# Data lake: one Cloud Storage bucket per zone. The buckets themselves are
# declared in storage.tf.
# -----------------------------------------------------------------------------

locals {
  lake_zones = {
    raw = {
      description = "Data as it arrives from the sources"
      zone_type   = "RAW"
      tiered      = true
    }
    processed = {
      description = "Cleaned and conformed data in columnar formats"
      zone_type   = "CURATED"
      tiered      = true
    }
    curated = {
      description = "Data sets that are ready for analysis"
      zone_type   = "CURATED"
      tiered      = false
    }
  }

  storage_classes    = { standard = "STANDARD", infrequent = "NEARLINE", archive = "ARCHIVE" }
  lake_storage_class = local.storage_classes[var.data_lake_storage_class]

  # New objects are written in STANDARD. In the raw and processed zones they move to
  # the chosen class as they age. The curated zone is read by queries and stays in STANDARD.
  lake_buckets = {
    for zone, settings in local.lake_zones : "lake-${zone}" => {
      name               = zone
      versioning         = true
      force_destroy      = !local.is_production
      transition_class   = settings.tiered && local.lake_storage_class != "STANDARD" ? local.lake_storage_class : null
      expire_after_days  = null
      object_role        = null
      object_role_member = null
    } if var.enable_data_lake
  }

  lake_bucket_names = { for zone in keys(local.lake_zones) : zone => google_storage_bucket.this["lake-${zone}"].name if var.enable_data_lake }
}

# -----------------------------------------------------------------------------
# Data catalog: a Dataplex lake with one zone per lake zone. Discovery scans the
# attached buckets and datasets and registers what it finds in the catalog.
# -----------------------------------------------------------------------------

resource "google_dataplex_lake" "this" {
  count = var.enable_data_catalog ? 1 : 0

  name         = "${local.name_prefix}-lake"
  location     = var.region
  display_name = "${var.project_name} ${var.environment} data lake"
  description  = "Lake and warehouse data of ${var.project_name} (${var.environment})"

  depends_on = [google_project_service.apis]
}

resource "google_dataplex_zone" "this" {
  for_each = var.enable_data_catalog ? local.lake_zones : {}

  name         = "${local.name_prefix}-${each.key}"
  lake         = google_dataplex_lake.this[0].name
  location     = var.region
  type         = each.value.zone_type
  display_name = "${each.key} zone"
  description  = each.value.description

  discovery_spec {
    enabled  = true
    schedule = var.catalog_discovery_schedule
  }

  resource_spec {
    location_type = "SINGLE_REGION"
  }
}

resource "google_dataplex_asset" "lake_bucket" {
  for_each = var.enable_data_catalog && var.enable_data_lake ? local.lake_zones : {}

  name          = "${each.key}-bucket"
  lake          = google_dataplex_lake.this[0].name
  dataplex_zone = google_dataplex_zone.this[each.key].name
  location      = var.region
  display_name  = "${each.key} bucket"

  discovery_spec {
    enabled  = true
    schedule = var.catalog_discovery_schedule
  }

  resource_spec {
    name = "projects/${var.gcp_project_id}/buckets/${local.lake_bucket_names[each.key]}"
    type = "STORAGE_BUCKET"
  }
}

resource "google_dataplex_asset" "warehouse_dataset" {
  for_each = var.enable_data_catalog && var.enable_data_warehouse ? local.warehouse_datasets : {}

  name          = "${each.key}-dataset"
  lake          = google_dataplex_lake.this[0].name
  dataplex_zone = google_dataplex_zone.this[each.value.zone].name
  location      = var.region
  display_name  = "${each.key} dataset"

  discovery_spec {
    enabled  = true
    schedule = var.catalog_discovery_schedule
  }

  resource_spec {
    name = "projects/${var.gcp_project_id}/datasets/${google_bigquery_dataset.this[each.key].dataset_id}"
    type = "BIGQUERY_DATASET"
  }
}

# Entries for sources outside Google Cloud and the aspect that describes a data product.
resource "google_dataplex_entry_group" "this" {
  count = var.enable_data_catalog ? 1 : 0

  entry_group_id = "${local.name_prefix}-sources"
  location       = var.region
  display_name   = "${var.project_name} ${var.environment} sources"
  description    = "Catalog entries for data sources that Dataplex does not discover by itself"

  depends_on = [google_project_service.apis]
}

resource "google_dataplex_aspect_type" "data_product" {
  count = var.enable_data_catalog ? 1 : 0

  aspect_type_id = "${local.name_prefix}-data-product"
  location       = var.region
  display_name   = "Data product"
  description    = "Ownership and sensitivity of a catalog entry"

  metadata_template = jsonencode({
    name = "data-product"
    type = "record"
    recordFields = [
      {
        name  = "owner"
        type  = "string"
        index = 1
        annotations = {
          displayName = "Owner"
          description = "Team that answers for the data"
        }
        constraints = {
          required = true
        }
      },
      {
        name  = "sensitivity"
        type  = "enum"
        index = 2
        annotations = {
          displayName = "Sensitivity"
          description = "How restricted the data is"
        }
        enumValues = [
          { name = "PUBLIC", index = 1 },
          { name = "INTERNAL", index = 2 },
          { name = "CONFIDENTIAL", index = 3 },
        ]
      },
    ]
  })

  depends_on = [google_project_service.apis]
}
