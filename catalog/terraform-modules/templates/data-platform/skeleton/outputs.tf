# Data Lake Outputs
{%- if values.enableDataLake %}
{%- if values.cloudProvider == "aws" %}
output "data_lake_bucket_arns" {
  description = "ARNs of data lake S3 buckets"
  value       = module.data_lake.bucket_arns
}

output "data_lake_bucket_names" {
  description = "Names of data lake S3 buckets"
  value       = module.data_lake.bucket_names
}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
output "data_lake_storage_account_id" {
  description = "ID of the data lake storage account"
  value       = module.data_lake.id
}

output "data_lake_primary_dfs_endpoint" {
  description = "Primary DFS endpoint"
  value       = module.data_lake.primary_dfs_endpoint
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
output "data_lake_bucket_urls" {
  description = "URLs of data lake GCS buckets"
  value       = module.data_lake.bucket_urls
}
{%- endif %}
{%- endif %}

# Data Warehouse Outputs
{%- if values.enableDataWarehouse %}
{%- if values.cloudProvider == "aws" %}
output "redshift_endpoint" {
  description = "Redshift cluster endpoint"
  value       = module.redshift.endpoint
}

output "redshift_database_name" {
  description = "Redshift database name"
  value       = module.redshift.database_name
}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
output "synapse_workspace_id" {
  description = "Synapse workspace ID"
  value       = module.synapse.id
}

output "synapse_connectivity_endpoints" {
  description = "Synapse connectivity endpoints"
  value       = module.synapse.connectivity_endpoints
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
output "bigquery_dataset_id" {
  description = "BigQuery dataset ID"
  value       = module.bigquery.dataset_id
}
{%- endif %}
{%- endif %}

# Data Catalog Outputs
{%- if values.enableDataCatalog %}
{%- if values.cloudProvider == "aws" %}
output "glue_catalog_database_name" {
  description = "Glue catalog database name"
  value       = module.glue_catalog.database_name
}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
output "purview_account_id" {
  description = "Purview account ID"
  value       = module.purview.id
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
output "data_catalog_entry_group_id" {
  description = "Data Catalog entry group ID"
  value       = module.data_catalog.entry_group_id
}
{%- endif %}
{%- endif %}

# Streaming Outputs
{%- if values.enableStreaming %}
{%- if values.cloudProvider == "aws" %}
output "kinesis_stream_arn" {
  description = "Kinesis stream ARN"
  value       = module.kinesis.stream_arn
}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
output "event_hubs_namespace_id" {
  description = "Event Hubs namespace ID"
  value       = module.event_hubs.namespace_id
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
output "pubsub_topic_id" {
  description = "Pub/Sub topic ID"
  value       = module.pubsub.topic_ids["data_stream"]
}
{%- endif %}
{%- endif %}
