locals {
  name_prefix   = "${var.project_name}-${var.environment}"
  is_production = var.environment == "production"

  # Service account IDs and Dataproc cluster names have short length limits,
  # so they use a short code for the environment.
  environment_code = { dev = "dev", staging = "stg", production = "prod" }[var.environment]
  short_prefix     = "${var.project_name}-${local.environment_code}"

  # BigQuery identifiers allow letters, digits and underscores only.
  dataset_prefix = replace(local.name_prefix, "-", "_")

  labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
    platform    = "data"
  }

  etl_native = var.enable_etl_pipelines && var.etl_engine == "native"
  etl_spark  = var.enable_etl_pipelines && var.etl_engine == "spark"

  # BI Engine and the reporting identity work on the warehouse, so they need it.
  bi_enabled = var.enable_bi_tools && var.enable_data_warehouse

  # Pipeline workers, the Airflow environment and the Workbench instance run in the VPC.
  needs_network = var.enable_etl_pipelines || var.enable_orchestration || var.enable_ml_platform

  # Features that create Cloud Storage buckets.
  needs_storage = var.enable_data_lake || var.enable_etl_pipelines || var.enable_ml_platform

  apis = toset(concat(
    ["cloudresourcemanager.googleapis.com", "iam.googleapis.com", "storage.googleapis.com"],
    var.enable_encryption ? ["cloudkms.googleapis.com"] : [],
    # Dataplex discovery publishes the tables it finds to BigQuery.
    var.enable_data_catalog ? ["dataplex.googleapis.com", "bigquery.googleapis.com"] : [],
    var.enable_data_warehouse ? ["bigquery.googleapis.com", "bigqueryreservation.googleapis.com"] : [],
    var.enable_data_warehouse && var.enable_access_control ? ["datacatalog.googleapis.com"] : [],
    local.needs_network ? ["compute.googleapis.com"] : [],
    local.etl_native ? ["dataflow.googleapis.com"] : [],
    local.etl_spark ? ["dataproc.googleapis.com"] : [],
    var.enable_orchestration ? ["composer.googleapis.com"] : [],
    var.enable_streaming ? ["pubsub.googleapis.com"] : [],
    var.enable_ml_platform ? ["aiplatform.googleapis.com", "notebooks.googleapis.com"] : [],
    var.enable_data_lineage ? ["datalineage.googleapis.com"] : [],
  ))
}

# -----------------------------------------------------------------------------
# Google APIs the enabled features use. They stay enabled when the stack is
# destroyed, because other workloads of the project may use them too.
# -----------------------------------------------------------------------------

resource "google_project_service" "apis" {
  for_each = local.apis

  project            = var.gcp_project_id
  service            = each.value
  disable_on_destroy = false
}
