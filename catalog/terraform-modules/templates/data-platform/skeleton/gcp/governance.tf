# -----------------------------------------------------------------------------
# Access to data. Every identity that works with the data has a profile: the role
# it needs on each lake zone and on each warehouse dataset.
#
# With enable_access_control the roles are granted on exactly those buckets and
# datasets, and a policy tag taxonomy protects sensitive columns. Without it each
# identity gets its broadest role on the whole project.
# -----------------------------------------------------------------------------

locals {
  data_profiles = {
    etl = {
      lake      = { raw = "roles/storage.objectViewer", processed = "roles/storage.objectUser", curated = "roles/storage.objectUser" }
      warehouse = { staging = "roles/bigquery.dataEditor", warehouse = "roles/bigquery.dataEditor", marts = "roles/bigquery.dataEditor" }
      project   = { lake = "roles/storage.objectUser", warehouse = "roles/bigquery.dataEditor" }
      # May read columns that carry a policy tag.
      reads_sensitive_columns = true
    }
    orchestration = {
      lake                    = { raw = "roles/storage.objectViewer", processed = "roles/storage.objectViewer", curated = "roles/storage.objectViewer" }
      warehouse               = { staging = "roles/bigquery.dataEditor", warehouse = "roles/bigquery.dataEditor", marts = "roles/bigquery.dataEditor" }
      project                 = { lake = "roles/storage.objectViewer", warehouse = "roles/bigquery.dataEditor" }
      reads_sensitive_columns = true
    }
    bi = {
      lake                    = {}
      warehouse               = { marts = "roles/bigquery.dataViewer" }
      project                 = { warehouse = "roles/bigquery.dataViewer" }
      reads_sensitive_columns = false
    }
    ml = {
      lake                    = { processed = "roles/storage.objectViewer", curated = "roles/storage.objectViewer" }
      warehouse               = { warehouse = "roles/bigquery.dataViewer", marts = "roles/bigquery.dataViewer" }
      project                 = { lake = "roles/storage.objectViewer", warehouse = "roles/bigquery.dataViewer" }
      reads_sensitive_columns = false
    }
    engineer = {
      lake                    = { raw = "roles/storage.objectUser", processed = "roles/storage.objectUser", curated = "roles/storage.objectUser" }
      warehouse               = { staging = "roles/bigquery.dataEditor", warehouse = "roles/bigquery.dataEditor", marts = "roles/bigquery.dataEditor" }
      project                 = { lake = "roles/storage.objectUser", warehouse = "roles/bigquery.dataEditor" }
      reads_sensitive_columns = true
    }
    analyst = {
      lake                    = { curated = "roles/storage.objectViewer" }
      warehouse               = { marts = "roles/bigquery.dataViewer" }
      project                 = { lake = "roles/storage.objectViewer", warehouse = "roles/bigquery.dataViewer" }
      reads_sensitive_columns = false
    }
  }

  # Identities that exist with the current settings. The keys are fixed; the
  # members of the service accounts are known once the accounts are created.
  data_principals = merge(
    var.enable_etl_pipelines ? {
      etl = { profile = "etl", member = "serviceAccount:${module.etl_service_account[0].service_account_email}" }
    } : {},
    var.enable_orchestration ? {
      orchestration = { profile = "orchestration", member = "serviceAccount:${module.orchestration_service_account[0].service_account_email}" }
    } : {},
    local.bi_enabled ? {
      bi = { profile = "bi", member = "serviceAccount:${module.bi_service_account[0].service_account_email}" }
    } : {},
    var.enable_ml_platform ? {
      ml = { profile = "ml", member = "serviceAccount:${module.ml_service_account[0].service_account_email}" }
    } : {},
    { for member in var.data_engineers : "engineer:${member}" => { profile = "engineer", member = member } },
    { for member in var.data_analysts : "analyst:${member}" => { profile = "analyst", member = member } },
  )

  fine_grained_lake      = var.enable_access_control && var.enable_data_lake
  fine_grained_warehouse = var.enable_access_control && var.enable_data_warehouse

  bucket_grants = merge([
    for key, principal in local.data_principals : {
      for zone, role in local.data_profiles[principal.profile].lake :
      "${key}/${zone}" => { member = principal.member, zone = zone, role = role }
    } if local.fine_grained_lake
  ]...)

  dataset_grants = merge([
    for key, principal in local.data_principals : {
      for dataset, role in local.data_profiles[principal.profile].warehouse :
      "${key}/${dataset}" => { member = principal.member, dataset = dataset, role = role }
    } if local.fine_grained_warehouse
  ]...)

  project_grants = merge([
    for key, principal in local.data_principals : {
      for scope, role in local.data_profiles[principal.profile].project :
      "${key}/${scope}" => { member = principal.member, role = role }
      if(scope == "lake" && var.enable_data_lake) || (scope == "warehouse" && var.enable_data_warehouse)
    } if !var.enable_access_control
  ]...)

  # Running a query is a project-level permission in BigQuery, whatever the access model.
  query_grants = {
    for key, principal in local.data_principals : key => principal.member
    if var.enable_data_warehouse && length(local.data_profiles[principal.profile].warehouse) > 0
  }

  sensitive_column_readers = {
    for key, principal in local.data_principals : key => principal.member
    if local.fine_grained_warehouse && local.data_profiles[principal.profile].reads_sensitive_columns
  }
}

resource "google_storage_bucket_iam_member" "data_access" {
  for_each = local.bucket_grants

  bucket = local.lake_bucket_names[each.value.zone]
  role   = each.value.role
  member = each.value.member
}

resource "google_bigquery_dataset_iam_member" "data_access" {
  for_each = local.dataset_grants

  dataset_id = google_bigquery_dataset.this[each.value.dataset].dataset_id
  role       = each.value.role
  member     = each.value.member
}

resource "google_project_iam_member" "data_access" {
  for_each = local.project_grants

  project = var.gcp_project_id
  role    = each.value.role
  member  = each.value.member
}

resource "google_project_iam_member" "query_jobs" {
  for_each = local.query_grants

  project = var.gcp_project_id
  role    = "roles/bigquery.jobUser"
  member  = each.value
}

# --- Sensitive columns --------------------------------------------------------

# Attach a policy tag to a column in a table schema to restrict it. Only the
# identities below read tagged columns; everyone else gets an access error on them.
resource "google_data_catalog_taxonomy" "sensitivity" {
  count = local.fine_grained_warehouse ? 1 : 0

  display_name           = "${local.name_prefix}-data-sensitivity"
  description            = "Sensitivity of warehouse columns of ${local.name_prefix}"
  region                 = var.region
  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]

  depends_on = [google_project_service.apis]
}

resource "google_data_catalog_policy_tag" "confidential" {
  count = local.fine_grained_warehouse ? 1 : 0

  taxonomy     = google_data_catalog_taxonomy.sensitivity[0].id
  display_name = "confidential"
  description  = "Business data with restricted access"
}

resource "google_data_catalog_policy_tag" "pii" {
  count = local.fine_grained_warehouse ? 1 : 0

  taxonomy          = google_data_catalog_taxonomy.sensitivity[0].id
  parent_policy_tag = google_data_catalog_policy_tag.confidential[0].id
  display_name      = "pii"
  description       = "Personal data"
}

resource "google_data_catalog_taxonomy_iam_member" "sensitive_column_reader" {
  for_each = local.sensitive_column_readers

  taxonomy = google_data_catalog_taxonomy.sensitivity[0].name
  role     = "roles/datacatalog.categoryFineGrainedReader"
  member   = each.value
}

# --- Project roles of the teams ----------------------------------------------

# Lineage, Vertex AI and Workbench have no finer level than the project.
module "team_project_roles" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/core/iam?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  project_id   = var.gcp_project_id
  environment  = var.environment

  project_iam_bindings = concat(
    var.enable_data_lineage ? [
      { role = "roles/datalineage.viewer", members = concat(var.data_engineers, var.data_analysts) },
    ] : [],
    var.enable_ml_platform ? [
      { role = "roles/aiplatform.user", members = var.data_scientists },
      { role = "roles/notebooks.viewer", members = var.data_scientists },
    ] : [],
  )

  depends_on = [google_project_service.apis]
}
