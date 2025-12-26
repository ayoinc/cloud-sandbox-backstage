{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
{%- endif %}

{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
{%- endif %}

{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
{%- endif %}

provider "random" {}
