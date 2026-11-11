# Plans the stack against mocked providers, so the tests need no Google Cloud project.
# Values not set in a run come from terraform.tfvars.

mock_provider "google" {
  mock_data "google_storage_project_service_account" {
    defaults = {
      member = "serviceAccount:service-123456789012@gs-project-accounts.iam.gserviceaccount.com"
    }
  }

  mock_data "google_bigquery_default_service_account" {
    defaults = {
      member = "serviceAccount:bq-123456789012@bigquery-encryption.iam.gserviceaccount.com"
    }
  }
}

mock_provider "google-beta" {}

run "configured_values" {
  command = plan

  assert {
    condition     = length(local.lake_bucket_names) == (var.enable_data_lake ? 3 : 0)
    error_message = "The lake has a bucket for each of its three zones exactly when enable_data_lake is true."
  }

  assert {
    condition     = length(google_dataplex_lake.this) == (var.enable_data_catalog ? 1 : 0)
    error_message = "A Dataplex lake exists exactly when enable_data_catalog is true."
  }

  assert {
    condition     = length(google_bigquery_dataset.this) == (var.enable_data_warehouse ? 3 : 0)
    error_message = "The warehouse has its three datasets exactly when enable_data_warehouse is true."
  }

  assert {
    condition     = length(module.etl_service_account) == (var.enable_etl_pipelines ? 1 : 0)
    error_message = "The pipeline identity exists exactly when enable_etl_pipelines is true."
  }

  assert {
    condition     = length(google_composer_environment.this) == (var.enable_orchestration ? 1 : 0)
    error_message = "A Composer environment exists exactly when enable_orchestration is true."
  }

  assert {
    condition     = length(module.events_topic) == (var.enable_streaming ? 1 : 0)
    error_message = "The events topic exists exactly when enable_streaming is true."
  }

  assert {
    condition     = length(google_workbench_instance.this) == (var.enable_ml_platform ? 1 : 0)
    error_message = "A Workbench instance exists exactly when enable_ml_platform is true."
  }

  assert {
    condition     = length(module.kms) == (var.enable_encryption ? 1 : 0)
    error_message = "The key ring exists exactly when enable_encryption is true."
  }

  assert {
    condition     = contains(local.apis, "datalineage.googleapis.com") == var.enable_data_lineage
    error_message = "The Data Lineage API is enabled exactly when enable_data_lineage is true."
  }

  assert {
    condition     = var.enable_access_control ? length(local.project_grants) == 0 : length(local.bucket_grants) + length(local.dataset_grants) == 0
    error_message = "Data roles are granted per bucket and dataset with enable_access_control, and on the project without it."
  }
}

run "everything_enabled_in_production" {
  command = plan

  # The longest names the portal accepts, to keep every derived name within its limit.
  variables {
    project_name              = "analytics-core-1"
    gcp_project_id            = "example-analytics-production-1"
    environment               = "production"
    enable_data_lake          = true
    data_lake_storage_class   = "archive"
    enable_data_catalog       = true
    enable_data_warehouse     = true
    warehouse_size            = "large"
    enable_etl_pipelines      = true
    etl_engine                = "spark"
    enable_orchestration      = true
    enable_streaming          = true
    streaming_retention_hours = 72
    enable_bi_tools           = true
    enable_ml_platform        = true
    enable_encryption         = true
    enable_data_lineage       = true
    enable_access_control     = true
    data_engineers            = ["group:data-engineers@example.com"]
    data_analysts             = ["group:data-analysts@example.com"]
    data_scientists           = ["group:data-scientists@example.com"]
  }

  assert {
    condition     = length(local.lake_buckets) == 3 && length(local.etl_buckets) == 2 && length(local.ml_buckets) == 1 && length(google_storage_bucket.this) == 6
    error_message = "Lake, pipeline and machine learning buckets are created."
  }

  assert {
    condition     = local.buckets["lake-raw"].transition_class == "ARCHIVE" && local.buckets["lake-curated"].transition_class == null
    error_message = "archive moves ageing objects of the raw zone to ARCHIVE and leaves the curated zone in STANDARD."
  }

  assert {
    condition     = alltrue([for bucket in google_storage_bucket.this : bucket.uniform_bucket_level_access && bucket.public_access_prevention == "enforced" && length(bucket.encryption) == 1 && length(bucket.name) <= 63])
    error_message = "Every bucket is private, uses uniform bucket-level access and the customer-managed key, and has a valid name."
  }

  assert {
    condition     = length(google_dataplex_zone.this) == 3 && length(google_dataplex_asset.lake_bucket) == 3 && length(google_dataplex_asset.warehouse_dataset) == 3
    error_message = "The catalog has three zones with the lake buckets and the warehouse datasets attached."
  }

  assert {
    condition     = google_bigquery_reservation.warehouse[0].autoscale[0].max_slots == 400 && google_bigquery_reservation.warehouse[0].edition == "ENTERPRISE"
    error_message = "A large warehouse scales to 400 Enterprise slots."
  }

  assert {
    condition     = alltrue([for dataset in google_bigquery_dataset.this : length(dataset.default_encryption_configuration) == 1 && !dataset.delete_contents_on_destroy])
    error_message = "Production datasets use the customer-managed key and keep their tables on destroy."
  }

  assert {
    condition     = length(google_dataproc_workflow_template.raw_to_processed) == 1 && length(google_dataproc_autoscaling_policy.etl) == 1 && length(google_dataflow_flex_template_job.etl) == 0
    error_message = "spark creates the Dataproc autoscaling policy and workflow template and no Dataflow job."
  }

  assert {
    condition     = google_dataproc_workflow_template.raw_to_processed[0].placement[0].managed_cluster[0].config[0].software_config[0].properties["dataproc:dataproc.lineage.enabled"] == "true"
    error_message = "Dataproc clusters report lineage when enable_data_lineage is true."
  }

  assert {
    condition     = google_composer_environment.this[0].config[0].environment_size == "ENVIRONMENT_SIZE_MEDIUM" && google_composer_environment.this[0].config[0].software_config[0].cloud_data_lineage_integration[0].enabled
    error_message = "Production runs a medium Composer environment that reports lineage."
  }

  assert {
    condition     = contains(local.orchestration_project_roles, "roles/dataproc.editor") && contains(local.etl_project_roles, "roles/datalineage.producer")
    error_message = "Airflow may launch Dataproc workflows and the workers may report lineage."
  }

  assert {
    condition     = local.streaming_retention == "259200s" && length(google_pubsub_subscription.to_lake) == 1 && length(google_pubsub_subscription.to_warehouse) == 1
    error_message = "Events are kept for 72 hours and written to the lake and to the warehouse."
  }

  assert {
    condition     = google_bigquery_bi_reservation.this[0].size == 4294967296 && length(module.bi_service_account) == 1
    error_message = "BI integration reserves 4 GB of BI Engine memory for a large warehouse and creates the read-only identity."
  }

  assert {
    condition     = length(google_workbench_instance.this) == 1 && google_workbench_instance.this[0].gce_setup[0].disable_public_ip
    error_message = "The Workbench instance has no public address."
  }

  assert {
    condition     = toset(keys(google_kms_crypto_key_iam_member.service_agent)) == toset(["storage", "bigquery", "pubsub"])
    error_message = "The storage, BigQuery and Pub/Sub service agents may use their keys."
  }

  assert {
    condition     = length(local.project_grants) == 0 && length(google_data_catalog_taxonomy.sensitivity) == 1
    error_message = "With access control no project-wide data role is granted and the policy tag taxonomy exists."
  }

  assert {
    condition     = google_storage_bucket_iam_member.data_access["analyst:group:data-analysts@example.com/curated"].role == "roles/storage.objectViewer" && !contains(keys(google_storage_bucket_iam_member.data_access), "analyst:group:data-analysts@example.com/raw")
    error_message = "Analysts read the curated zone only."
  }

  assert {
    condition     = google_bigquery_dataset_iam_member.data_access["bi/marts"].role == "roles/bigquery.dataViewer" && !contains(keys(google_bigquery_dataset_iam_member.data_access), "bi/warehouse")
    error_message = "The BI identity reads the marts dataset only."
  }

  assert {
    condition     = contains(keys(google_data_catalog_taxonomy_iam_member.sensitive_column_reader), "etl") && !contains(keys(google_data_catalog_taxonomy_iam_member.sensitive_column_reader), "bi")
    error_message = "Pipelines read tagged columns, the BI identity does not."
  }
}

run "lake_only" {
  command = plan

  variables {
    enable_data_lake        = true
    data_lake_storage_class = "standard"
    enable_data_catalog     = false
    enable_data_warehouse   = false
    enable_etl_pipelines    = false
    enable_orchestration    = false
    enable_streaming        = false
    enable_bi_tools         = false
    enable_ml_platform      = false
    enable_encryption       = false
    enable_data_lineage     = false
    enable_access_control   = false
  }

  assert {
    condition     = length(google_storage_bucket.this) == 3 && alltrue([for bucket in local.buckets : bucket.transition_class == null])
    error_message = "standard creates the three zone buckets without storage class transitions."
  }

  assert {
    condition     = length(module.network) == 0 && length(module.kms) == 0 && length(google_kms_crypto_key_iam_member.service_agent) == 0
    error_message = "A lake on its own needs no network and, without encryption, no keys."
  }

  assert {
    condition     = local.apis == toset(["cloudresourcemanager.googleapis.com", "iam.googleapis.com", "storage.googleapis.com"])
    error_message = "Only the APIs of the enabled features are enabled."
  }

  assert {
    condition = alltrue([
      length(google_dataplex_lake.this) == 0,
      length(google_bigquery_dataset.this) == 0,
      length(google_bigquery_reservation.warehouse) == 0,
      length(module.etl_service_account) == 0,
      length(google_composer_environment.this) == 0,
      length(module.events_topic) == 0,
      length(google_bigquery_bi_reservation.this) == 0,
      length(google_workbench_instance.this) == 0,
      length(google_data_catalog_taxonomy.sensitivity) == 0,
    ])
    error_message = "Disabled features create nothing."
  }
}

run "dataflow_with_a_flex_template" {
  command = plan

  variables {
    environment                     = "staging"
    enable_data_lake                = true
    data_lake_storage_class         = "infrequent"
    enable_data_warehouse           = true
    warehouse_size                  = "medium"
    enable_etl_pipelines            = true
    etl_engine                      = "native"
    enable_orchestration            = true
    enable_data_lineage             = true
    dataflow_flex_template_gcs_path = "gs://example-templates/raw-to-processed.json"
  }

  assert {
    condition     = local.buckets["lake-processed"].transition_class == "NEARLINE"
    error_message = "infrequent moves ageing objects of the processed zone to NEARLINE."
  }

  assert {
    condition     = google_bigquery_reservation.warehouse[0].autoscale[0].max_slots == 200
    error_message = "A medium warehouse scales to 200 slots."
  }

  assert {
    condition     = length(google_dataflow_flex_template_job.etl) == 1 && contains(google_dataflow_flex_template_job.etl[0].additional_experiments, "enable_lineage=true")
    error_message = "native launches the Flex Template as a Dataflow job that reports lineage."
  }

  assert {
    condition     = length(google_dataproc_workflow_template.raw_to_processed) == 0 && length(google_dataproc_autoscaling_policy.etl) == 0
    error_message = "native creates no Dataproc resources."
  }

  assert {
    condition     = contains(local.etl_project_roles, "roles/dataflow.worker") && contains(local.orchestration_project_roles, "roles/dataflow.developer")
    error_message = "The workers run Dataflow jobs and Airflow may launch them."
  }

  assert {
    condition     = google_composer_environment.this[0].config[0].environment_size == "ENVIRONMENT_SIZE_SMALL" && length(google_service_account_iam_member.orchestration_runs_etl) == 1
    error_message = "Outside production the Composer environment is small, and Airflow may act as the pipeline identity."
  }
}

run "dataflow_without_a_template" {
  command = plan

  variables {
    enable_etl_pipelines = true
    etl_engine           = "native"
    enable_data_lineage  = false
  }

  assert {
    condition     = length(google_dataflow_flex_template_job.etl) == 0 && length(local.etl_buckets) == 2 && length(module.network) == 1
    error_message = "Without a template, native prepares the identity, buckets and network and launches no job."
  }

  assert {
    condition     = !contains(local.etl_project_roles, "roles/datalineage.producer") && !contains(local.apis, "datalineage.googleapis.com")
    error_message = "Without data lineage the API stays off and the workers get no lineage role."
  }
}

run "spark_without_a_lake" {
  command = plan

  variables {
    enable_data_lake     = false
    enable_etl_pipelines = true
    etl_engine           = "spark"
  }

  assert {
    condition     = length(google_dataproc_autoscaling_policy.etl) == 1 && length(google_dataproc_workflow_template.raw_to_processed) == 0
    error_message = "Without a lake, spark keeps the autoscaling policy and omits the raw-to-processed workflow."
  }
}

run "warehouse_without_a_lake" {
  command = plan

  variables {
    enable_data_lake          = false
    enable_data_catalog       = true
    enable_data_warehouse     = true
    warehouse_size            = "small"
    enable_streaming          = true
    streaming_retention_hours = 24
    enable_bi_tools           = true
  }

  assert {
    condition     = length(google_dataplex_asset.lake_bucket) == 0 && length(google_dataplex_asset.warehouse_dataset) == 3
    error_message = "Without a lake the catalog covers the warehouse datasets only."
  }

  assert {
    condition     = length(google_pubsub_subscription.to_warehouse) == 1 && length(google_pubsub_subscription.to_lake) == 0 && length(google_bigquery_table.events) == 1
    error_message = "Without a lake the events are written to the warehouse only."
  }

  assert {
    condition     = google_bigquery_reservation.warehouse[0].autoscale[0].max_slots == 100 && google_bigquery_bi_reservation.this[0].size == 1073741824
    error_message = "A small warehouse scales to 100 slots and reserves 1 GB of BI Engine memory."
  }

  assert {
    condition     = local.streaming_retention == "86400s"
    error_message = "24 hours of retention are 86400 seconds."
  }
}

run "streaming_on_its_own" {
  command = plan

  variables {
    enable_data_lake          = false
    enable_data_catalog       = false
    enable_data_warehouse     = false
    enable_etl_pipelines      = false
    enable_orchestration      = false
    enable_streaming          = true
    streaming_retention_hours = 2000
    enable_bi_tools           = true
    enable_ml_platform        = false
    enable_encryption         = true
  }

  assert {
    condition     = length(module.events_topic) == 1 && length(google_pubsub_subscription.to_lake) == 0 && length(google_pubsub_subscription.to_warehouse) == 0
    error_message = "Without lake and warehouse the topic keeps its pull subscription and has no export subscriptions."
  }

  assert {
    condition     = local.streaming_retention == "2678400s"
    error_message = "Retention is capped at the 31 days Pub/Sub supports."
  }

  assert {
    condition     = toset(keys(google_kms_crypto_key_iam_member.service_agent)) == toset(["pubsub"])
    error_message = "Only the service agent of a service in use may use its key."
  }

  assert {
    condition     = length(module.bi_service_account) == 0 && length(google_bigquery_bi_reservation.this) == 0
    error_message = "BI integration needs the warehouse and creates nothing without it."
  }
}

run "streaming_into_the_lake" {
  command = plan

  variables {
    enable_data_lake          = true
    enable_data_warehouse     = false
    enable_streaming          = true
    streaming_retention_hours = 0
    enable_encryption         = false
  }

  assert {
    condition     = length(google_pubsub_subscription.to_lake) == 1 && length(google_pubsub_subscription.to_warehouse) == 0 && length(google_storage_bucket_iam_member.pubsub_lake_writer) == 2
    error_message = "Without a warehouse the events are written to the raw zone, which Pub/Sub may write to."
  }

  assert {
    condition     = local.streaming_retention == "600s"
    error_message = "Retention is at least the 10 minutes Pub/Sub supports."
  }

  assert {
    condition     = length(module.kms) == 0 && length(google_kms_crypto_key_iam_member.service_agent) == 0
    error_message = "Without encryption no customer-managed keys are created."
  }
}

run "project_wide_access" {
  command = plan

  variables {
    enable_data_lake      = true
    enable_data_warehouse = true
    enable_etl_pipelines  = true
    enable_bi_tools       = true
    enable_ml_platform    = true
    enable_access_control = false
    data_analysts         = ["user:analyst@example.com"]
  }

  assert {
    condition     = length(google_storage_bucket_iam_member.data_access) == 0 && length(google_bigquery_dataset_iam_member.data_access) == 0 && length(google_data_catalog_taxonomy.sensitivity) == 0
    error_message = "Without access control there are no bucket or dataset grants and no policy tags."
  }

  assert {
    condition     = google_project_iam_member.data_access["etl/lake"].role == "roles/storage.objectUser" && google_project_iam_member.data_access["bi/warehouse"].role == "roles/bigquery.dataViewer" && google_project_iam_member.data_access["analyst:user:analyst@example.com/warehouse"].role == "roles/bigquery.dataViewer"
    error_message = "Without access control every identity gets its data roles on the project."
  }

  assert {
    condition     = !contains(local.apis, "datacatalog.googleapis.com")
    error_message = "The Data Catalog API is needed for policy tags only."
  }
}
