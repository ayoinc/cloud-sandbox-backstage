{%- set aws = values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' -%}
{%- set azure = values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' -%}
{%- set gcp = values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' -%}
{%- set datadog = values.monitoring_solution == 'datadog' -%}
{%- set newrelic = values.monitoring_solution == 'new-relic' -%}
{%- set elastic = values.monitoring_solution == 'elastic-stack' -%}
{%- if values.cloud_provider == 'azure' -%}
# Remote state in Azure Blob Storage, one state file per environment. The
# storage account, container and key are passed to `terraform init` with
# -backend-config; see README.md.
terraform {
  backend "azurerm" {
    use_azuread_auth = true
  }
}
{%- elif values.cloud_provider == 'gcp' -%}
# Remote state in Cloud Storage, one prefix per environment. The bucket and
# prefix are passed to `terraform init` with -backend-config; see README.md.
terraform {
  backend "gcs" {}
}
{%- else -%}
# Remote state in S3, one state file per environment. The bucket, key and
# region are passed to `terraform init` with -backend-config; see README.md.
terraform {
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}
{%- endif %}
