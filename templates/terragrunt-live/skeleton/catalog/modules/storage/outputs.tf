{%- if values.cloud == 'aws' -%}
output "bucket_name" {
  description = "Name of the log bucket."
  value       = aws_s3_bucket.logs.bucket
}

output "bucket_arn" {
  description = "ARN of the log bucket."
  value       = aws_s3_bucket.logs.arn
}
{%- elif values.cloud == 'azure' -%}
output "storage_account_name" {
  description = "Name of the log storage account."
  value       = azurerm_storage_account.logs.name
}

output "container_name" {
  description = "Name of the log container."
  value       = azurerm_storage_container.logs.name
}
{%- else -%}
output "bucket_name" {
  description = "Name of the log bucket."
  value       = google_storage_bucket.logs.name
}

output "bucket_url" {
  description = "gs:// URL of the log bucket."
  value       = google_storage_bucket.logs.url
}
{%- endif %}
