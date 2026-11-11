{%- if values.cloud == 'aws' -%}
provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}
{%- elif values.cloud == 'azure' -%}
# The subscription comes from ARM_SUBSCRIPTION_ID, or from the Azure CLI when
# run locally.
provider "azurerm" {
  storage_use_azuread = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}
{%- else -%}
provider "google" {
  project = var.project_id
  region  = var.region

  default_labels = local.tags
}
{%- endif %}
