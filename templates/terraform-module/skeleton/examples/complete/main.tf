{%- set aws = values.provider == 'aws' or values.provider == 'multi-cloud' -%}
{%- set azure = values.provider == 'azure' or values.provider == 'multi-cloud' -%}
{%- set gcp = values.provider == 'gcp' or values.provider == 'multi-cloud' -%}
# Complete example: configures the provider{% if values.provider == 'multi-cloud' %}s{% endif %} and calls the module with the
# building blocks chosen in terraform.tfvars.
{%- if aws %}

provider "aws" {
  region = var.aws_region
}
{%- endif %}
{%- if azure %}

# The subscription comes from ARM_SUBSCRIPTION_ID.
provider "azurerm" {
  features {
    # Storage accounts deny public network access, so the provider must not
    # read their settings through the data plane.
    storage {
      data_plane_available = false
    }
  }
}
{%- endif %}
{%- if gcp %}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
{%- endif %}

module "platform" {
  source = "../../"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
{%- if azure %}

  azure_location = var.azure_location
{%- endif %}
{%- if gcp %}

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
{%- endif %}

  enable_network       = var.enable_network
  enable_security      = var.enable_security
  enable_storage       = var.enable_storage
  enable_observability = var.enable_observability
  enable_compute       = var.enable_compute
  enable_database      = var.enable_database
  enable_kubernetes    = var.enable_kubernetes
  enable_serverless    = var.enable_serverless
}
