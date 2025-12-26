terraform {
  required_version = "${{ values.terraform_version }}"

  required_providers {
{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
{%- endif %}
{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
{%- endif %}
{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0"
    }
{%- endif %}
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
