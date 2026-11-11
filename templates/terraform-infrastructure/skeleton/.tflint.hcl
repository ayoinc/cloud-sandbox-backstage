{%- set aws = values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' -%}
{%- set azure = values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' -%}
{%- set gcp = values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' -%}
{%- set datadog = values.monitoring_solution == 'datadog' -%}
{%- set newrelic = values.monitoring_solution == 'new-relic' -%}
{%- set elastic = values.monitoring_solution == 'elastic-stack' -%}
config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
{%- if aws %}

plugin "aws" {
  enabled = true
  version = "0.50.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
{%- endif %}
{%- if azure %}

plugin "azurerm" {
  enabled = true
  version = "0.33.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# The pipeline must be able to destroy what it created, and
# `prevent_destroy` cannot be made conditional; data is protected by purge
# protection, soft delete and versioning instead.
rule "azurerm_resources_missing_prevent_destroy" {
  enabled = false
}
{%- endif %}
{%- if gcp %}

plugin "google" {
  enabled = true
  version = "0.41.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}
{%- endif %}
