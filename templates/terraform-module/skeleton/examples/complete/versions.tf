{%- set aws = values.provider == 'aws' or values.provider == 'multi-cloud' -%}
{%- set azure = values.provider == 'azure' or values.provider == 'multi-cloud' -%}
{%- set gcp = values.provider == 'gcp' or values.provider == 'multi-cloud' -%}
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
{%- endif %}
{%- if gcp %}
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
{%- endif %}
  }
}
