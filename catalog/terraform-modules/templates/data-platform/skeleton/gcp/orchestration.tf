# -----------------------------------------------------------------------------
# Workflow orchestration: a Cloud Composer 3 environment (managed Airflow) with
# private networking, attached to the VPC.
# -----------------------------------------------------------------------------

locals {
  # Besides running the environment, Airflow launches the pipelines of the chosen engine.
  orchestration_project_roles = concat(
    ["roles/composer.worker"],
    local.etl_native ? ["roles/dataflow.developer"] : [],
    local.etl_spark ? ["roles/dataproc.editor"] : [],
    var.enable_data_lineage ? ["roles/datalineage.producer"] : [],
  )
}

module "orchestration_service_account" {
  count  = var.enable_orchestration ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/core/service-account?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  project_id   = var.gcp_project_id
  environment  = var.environment

  account_id   = "${local.short_prefix}-orch"
  display_name = "${local.name_prefix} Airflow"
  description  = "Identity of the Cloud Composer environment of ${local.name_prefix}"

  project_roles = local.orchestration_project_roles

  depends_on = [google_project_service.apis]
}

# Airflow starts pipeline workers that run as the ETL identity.
resource "google_service_account_iam_member" "orchestration_runs_etl" {
  count = var.enable_orchestration && var.enable_etl_pipelines ? 1 : 0

  service_account_id = module.etl_service_account[0].service_account_name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.orchestration_service_account[0].service_account_email}"
}

locals {
  # Names of the platform's resources, for DAGs to read with os.environ.
  airflow_environment = merge(
    {
      DATA_PLATFORM_ENVIRONMENT = var.environment
      DATA_PLATFORM_REGION      = var.region
    },
    { for zone, name in local.lake_bucket_names : "DATA_LAKE_${upper(zone)}_BUCKET" => name },
    { for name, dataset in google_bigquery_dataset.this : "WAREHOUSE_${upper(name)}_DATASET" => dataset.dataset_id },
    var.enable_etl_pipelines ? {
      ETL_ENGINE          = local.etl_native ? "dataflow" : "dataproc"
      ETL_SERVICE_ACCOUNT = module.etl_service_account[0].service_account_email
      ETL_STAGING_BUCKET  = google_storage_bucket.this["etl-staging"].name
      ETL_TEMP_BUCKET     = google_storage_bucket.this["etl-temp"].name
      ETL_SUBNETWORK      = module.network[0].subnet_self_links["data"]
    } : {},
    local.spark_workflow ? { ETL_WORKFLOW_TEMPLATE = google_dataproc_workflow_template.raw_to_processed[0].name } : {},
    var.enable_streaming ? {
      EVENTS_TOPIC        = module.events_topic[0].topic_id
      EVENTS_SUBSCRIPTION = google_pubsub_subscription.pull[0].id
    } : {},
  )
}

resource "google_composer_environment" "this" {
  count = var.enable_orchestration ? 1 : 0

  name   = "${local.name_prefix}-airflow"
  region = var.region

  config {
    environment_size           = local.is_production ? "ENVIRONMENT_SIZE_MEDIUM" : "ENVIRONMENT_SIZE_SMALL"
    enable_private_environment = true

    software_config {
      image_version = var.composer_image_version
      env_variables = local.airflow_environment

      cloud_data_lineage_integration {
        enabled = var.enable_data_lineage
      }
    }

    node_config {
      network         = module.network[0].network_id
      subnetwork      = module.network[0].subnet_ids["data"]
      service_account = module.orchestration_service_account[0].service_account_email
    }
  }

  # The environment is created only after its identity holds the Composer worker role.
  depends_on = [google_project_service.apis, module.orchestration_service_account]
}
