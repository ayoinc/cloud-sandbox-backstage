# -----------------------------------------------------------------------------
# ETL/ELT pipelines. Both engines share the worker identity and the staging and
# temporary buckets. etl_engine native prepares Dataflow, spark prepares Dataproc.
# -----------------------------------------------------------------------------

locals {
  etl_buckets = var.enable_etl_pipelines ? {
    etl-staging = {
      name               = "etl-staging"
      versioning         = true
      force_destroy      = true
      transition_class   = null
      expire_after_days  = null
      object_role        = "roles/storage.objectUser"
      object_role_member = "serviceAccount:${module.etl_service_account[0].service_account_email}"
    }
    etl-temp = {
      name               = "etl-temp"
      versioning         = false
      force_destroy      = true
      transition_class   = null
      expire_after_days  = 7
      object_role        = "roles/storage.objectUser"
      object_role_member = "serviceAccount:${module.etl_service_account[0].service_account_email}"
    }
  } : {}

  # The Spark workflow converts the raw zone into the processed zone, so it needs the lake.
  spark_workflow = local.etl_spark && var.enable_data_lake

  etl_project_roles = concat(
    [local.etl_native ? "roles/dataflow.worker" : "roles/dataproc.worker"],
    var.enable_data_lineage ? ["roles/datalineage.producer"] : [],
  )
}

module "etl_service_account" {
  count  = var.enable_etl_pipelines ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/gcp/resources/core/service-account?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  project_id   = var.gcp_project_id
  environment  = var.environment

  account_id   = "${local.short_prefix}-etl"
  display_name = "${local.name_prefix} pipeline workers"
  description  = "Identity of the ${local.etl_native ? "Dataflow" : "Dataproc"} workers of ${local.name_prefix}"

  project_roles = local.etl_project_roles

  depends_on = [google_project_service.apis]
}

# --- Dataflow (etl_engine = "native") -----------------------------------------

# A Dataflow job runs a Flex Template, which is built from pipeline code. No job is
# created until dataflow_flex_template_gcs_path points to the template to run.
resource "google_dataflow_flex_template_job" "etl" {
  count = local.etl_native && var.dataflow_flex_template_gcs_path != null ? 1 : 0

  name                    = "${local.name_prefix}-etl"
  region                  = var.region
  container_spec_gcs_path = var.dataflow_flex_template_gcs_path
  parameters              = var.dataflow_flex_template_parameters

  service_account_email = module.etl_service_account[0].service_account_email
  subnetwork            = module.network[0].subnet_self_links["data"]
  ip_configuration      = "WORKER_IP_PRIVATE"
  staging_location      = "gs://${google_storage_bucket.this["etl-staging"].name}/dataflow/staging"
  temp_location         = "gs://${google_storage_bucket.this["etl-temp"].name}/dataflow/temp"
  max_workers           = var.dataflow_max_workers

  additional_experiments = var.enable_data_lineage ? ["enable_lineage=true"] : []

  depends_on = [module.etl_service_account, google_storage_bucket_iam_member.owner_workload]
}

# --- Dataproc (etl_engine = "spark") ------------------------------------------

resource "google_dataproc_autoscaling_policy" "etl" {
  count = local.etl_spark ? 1 : 0

  policy_id = "${local.name_prefix}-etl"
  location  = var.region

  worker_config {
    min_instances = 2
    max_instances = var.spark_max_workers
  }

  basic_algorithm {
    cooldown_period = "120s"

    yarn_config {
      graceful_decommission_timeout = "3600s"
      scale_up_factor               = 0.5
      scale_down_factor             = 0.5
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_storage_bucket_object" "spark_job" {
  count = local.spark_workflow ? 1 : 0

  bucket       = google_storage_bucket.this["etl-staging"].name
  name         = "jobs/raw_to_processed.py"
  source       = "${path.module}/jobs/raw_to_processed.py"
  content_type = "text/x-python"
}

# A workflow template costs nothing until it is instantiated. Each run creates a
# cluster, runs the job and deletes the cluster again.
resource "google_dataproc_workflow_template" "raw_to_processed" {
  count = local.spark_workflow ? 1 : 0

  name     = "${local.name_prefix}-raw-to-processed"
  location = var.region

  placement {
    managed_cluster {
      cluster_name = "${local.short_prefix}-etl"

      config {
        staging_bucket = google_storage_bucket.this["etl-staging"].name
        temp_bucket    = google_storage_bucket.this["etl-temp"].name

        autoscaling_config {
          policy = google_dataproc_autoscaling_policy.etl[0].id
        }

        gce_cluster_config {
          subnetwork             = module.network[0].subnet_self_links["data"]
          internal_ip_only       = true
          service_account        = module.etl_service_account[0].service_account_email
          service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

          shielded_instance_config {
            enable_secure_boot          = true
            enable_vtpm                 = true
            enable_integrity_monitoring = true
          }
        }

        master_config {
          num_instances = 1
          machine_type  = var.spark_machine_type

          disk_config {
            boot_disk_type    = "pd-balanced"
            boot_disk_size_gb = 100
          }
        }

        worker_config {
          num_instances = 2
          machine_type  = var.spark_machine_type

          disk_config {
            boot_disk_type    = "pd-balanced"
            boot_disk_size_gb = 100
          }
        }

        software_config {
          image_version = var.dataproc_image_version
          properties    = var.enable_data_lineage ? { "dataproc:dataproc.lineage.enabled" = "true" } : {}
        }
      }
    }
  }

  jobs {
    step_id = "raw-to-processed"

    pyspark_job {
      main_python_file_uri = "gs://${google_storage_bucket_object.spark_job[0].bucket}/${google_storage_bucket_object.spark_job[0].name}"

      args = [
        "--source", "gs://${local.lake_bucket_names["raw"]}/landing/",
        "--target", "gs://${local.lake_bucket_names["processed"]}/landing/",
      ]
    }
  }

  depends_on = [module.etl_service_account, google_storage_bucket_iam_member.owner_workload]
}
