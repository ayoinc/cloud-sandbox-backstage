{%- set aws = values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' -%}
{%- set azure = values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' -%}
{%- set gcp = values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' -%}
{%- set datadog = values.monitoring_solution == 'datadog' -%}
{%- set newrelic = values.monitoring_solution == 'new-relic' -%}
{%- set elastic = values.monitoring_solution == 'elastic-stack' -%}
terraform {
  required_version = "${{ values.terraform_version }}"

  required_providers {
{%- if aws %}
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
{%- endif %}
{%- if azure %}
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
{%- if datadog or newrelic %}
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
{%- endif %}
{%- endif %}
{%- if gcp %}
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 8.0"
    }
{%- endif %}
{%- if datadog %}
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 4.0"
    }
{%- endif %}
{%- if newrelic %}
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 3.0"
    }
{%- endif %}
{%- if elastic %}
    ec = {
      source  = "elastic/ec"
      version = "~> 0.14"
    }
{%- endif %}
  }
}
