output "lake_bucket_names" {
  description = "Cloud Storage bucket of each lake zone, when enable_data_lake is true"
  value       = local.lake_bucket_names
}

output "dataplex_lake_name" {
  description = "Dataplex lake, when enable_data_catalog is true"
  value       = one(google_dataplex_lake.this[*].name)
}

output "warehouse_dataset_ids" {
  description = "BigQuery dataset of each warehouse layer, when enable_data_warehouse is true"
  value       = { for name, dataset in google_bigquery_dataset.this : name => dataset.dataset_id }
}

output "warehouse_reservation_name" {
  description = "BigQuery slot reservation, when enable_data_warehouse is true"
  value       = one(google_bigquery_reservation.warehouse[*].name)
}

output "etl_service_account_email" {
  description = "Identity of the pipeline workers, when enable_etl_pipelines is true"
  value       = one(module.etl_service_account[*].service_account_email)
}

output "etl_bucket_names" {
  description = "Staging and temporary buckets of the pipelines, when enable_etl_pipelines is true"
  value       = { for key in keys(local.etl_buckets) : trimprefix(key, "etl-") => google_storage_bucket.this[key].name }
}

output "etl_subnetwork" {
  description = "Subnet that pipeline workers, Airflow and the Workbench instance run in"
  value       = one(module.network[*].subnet_self_links["data"])
}

output "dataflow_job_id" {
  description = "Dataflow job, when etl_engine is native and dataflow_flex_template_gcs_path is set"
  value       = one(google_dataflow_flex_template_job.etl[*].job_id)
}

output "dataproc_workflow_template" {
  description = "Dataproc workflow template that converts the raw zone into the processed zone, when etl_engine is spark"
  value       = one(google_dataproc_workflow_template.raw_to_processed[*].id)
}

output "airflow_uri" {
  description = "Address of the Airflow web interface, when enable_orchestration is true"
  value       = one(google_composer_environment.this[*].config[0].airflow_uri)
}

output "airflow_dag_gcs_prefix" {
  description = "Cloud Storage folder that Airflow loads DAGs from, when enable_orchestration is true"
  value       = one(google_composer_environment.this[*].config[0].dag_gcs_prefix)
}

output "events_topic" {
  description = "Pub/Sub topic that events are published to, when enable_streaming is true"
  value       = one(module.events_topic[*].topic_id)
}

output "events_pull_subscription" {
  description = "Pub/Sub subscription for pipelines that read the events, when enable_streaming is true"
  value       = one(google_pubsub_subscription.pull[*].id)
}

output "events_table" {
  description = "BigQuery table that Pub/Sub writes the events to, when streaming and the warehouse are enabled"
  value       = one(google_bigquery_table.events[*].id)
}

output "bi_service_account_email" {
  description = "Read-only identity for BI tools, when BI integration and the warehouse are enabled"
  value       = one(module.bi_service_account[*].service_account_email)
}

output "ml_service_account_email" {
  description = "Identity of the Workbench instance and Vertex AI jobs, when enable_ml_platform is true"
  value       = one(module.ml_service_account[*].service_account_email)
}

output "ml_bucket_name" {
  description = "Bucket for machine learning artifacts, when enable_ml_platform is true"
  value       = one([for key in keys(local.ml_buckets) : google_storage_bucket.this[key].name])
}

output "workbench_proxy_uri" {
  description = "Address of JupyterLab on the Workbench instance, when enable_ml_platform is true"
  value       = one(google_workbench_instance.this[*].proxy_uri)
}

output "kms_key_ids" {
  description = "Customer-managed keys by service, when enable_encryption is true"
  value       = one(module.kms[*].crypto_key_ids)
}

output "policy_tag_ids" {
  description = "Policy tags to attach to sensitive columns, when access control and the warehouse are enabled"
  value = local.fine_grained_warehouse ? {
    confidential = google_data_catalog_policy_tag.confidential[0].id
    pii          = google_data_catalog_policy_tag.pii[0].id
  } : {}
}
