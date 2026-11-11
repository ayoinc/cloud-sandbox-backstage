output "data_lake_buckets" {
  description = "S3 bucket of each data lake zone, when enable_data_lake is true"
  value       = { for zone, bucket in module.lake : zone => bucket.bucket_name }
}

output "artifacts_bucket" {
  description = "S3 bucket for job scripts, logs and query results, when ETL, BI or ML is enabled"
  value       = local.artifacts_bucket
}

output "kms_key_arn" {
  description = "ARN of the customer managed KMS key, when enable_encryption is true"
  value       = local.kms_key_arn
}

output "catalog_databases" {
  description = "Glue database of each zone, when enable_data_catalog is true"
  value       = { for zone, database in aws_glue_catalog_database.zone : zone => database.name }
}

output "crawlers" {
  description = "Glue crawler of each zone, when the data catalog and the data lake are enabled"
  value       = { for zone, crawler in aws_glue_crawler.zone : zone => crawler.name }
}

output "warehouse_endpoint" {
  description = "Endpoint of the Redshift cluster, when enable_data_warehouse is true"
  value       = one(aws_redshift_cluster.warehouse[*].endpoint)
}

output "warehouse_database" {
  description = "Name of the first database of the Redshift cluster"
  value       = one(aws_redshift_cluster.warehouse[*].database_name)
}

output "warehouse_admin_secret_arn" {
  description = "ARN of the Secrets Manager secret that holds the Redshift admin password"
  value       = one(aws_redshift_cluster.warehouse[*].master_password_secret_arn)
}

output "etl_glue_jobs" {
  description = "Names of the Glue jobs, when etl_engine is native"
  value       = [for key in local.etl_stage_order : aws_glue_job.etl[key].name if local.etl_native]
}

output "etl_emr_application_id" {
  description = "ID of the EMR Serverless application, when etl_engine is spark"
  value       = one(aws_emrserverless_application.etl[*].id)
}

output "etl_role_arn" {
  description = "ARN of the IAM role the ETL jobs run with"
  value       = var.enable_etl_pipelines ? module.role["etl"].role_arn : null
}

output "pipeline_state_machine_arn" {
  description = "ARN of the Step Functions state machine that runs the pipeline, when it has at least one step"
  value       = one(aws_sfn_state_machine.pipeline[*].arn)
}

output "pipeline_steps" {
  description = "First state of each step of the pipeline, in order"
  value       = local.pipeline_enabled ? local.pipeline_steps[*].entry : []
}

output "event_stream_name" {
  description = "Name of the Kinesis data stream, when enable_streaming is true"
  value       = one(aws_kinesis_stream.events[*].name)
}

output "event_delivery_stream_name" {
  description = "Name of the Firehose stream that delivers events to the raw zone"
  value       = one(aws_kinesis_firehose_delivery_stream.lake[*].name)
}

output "athena_workgroups" {
  description = "Athena workgroup of the BI tools (bi) and of the ML platform (ml)"
  value       = { for consumer, workgroup in aws_athena_workgroup.consumer : consumer => workgroup.name }
}

output "bi_role_arn" {
  description = "ARN of the IAM role BI tools assume to query the lake, when enable_bi_tools is true"
  value       = var.enable_bi_tools ? module.role["bi"].role_arn : null
}

output "sagemaker_domain_id" {
  description = "ID of the SageMaker domain, when enable_ml_platform is true"
  value       = one(aws_sagemaker_domain.ml[*].id)
}

output "sagemaker_domain_url" {
  description = "URL of the SageMaker domain"
  value       = one(aws_sagemaker_domain.ml[*].url)
}

output "lineage_domain_id" {
  description = "ID of the DataZone domain that stores data lineage, when enable_data_lineage is true"
  value       = one(aws_datazone_domain.lineage[*].id)
}

output "lineage_portal_url" {
  description = "URL of the DataZone data portal"
  value       = one(aws_datazone_domain.lineage[*].portal_url)
}

output "lake_formation_registered_buckets" {
  description = "Data lake buckets registered with Lake Formation, when enable_access_control is true"
  value       = [for zone in local.zones : aws_lakeformation_resource.lake[zone].arn if var.enable_access_control && var.enable_data_lake]
}
