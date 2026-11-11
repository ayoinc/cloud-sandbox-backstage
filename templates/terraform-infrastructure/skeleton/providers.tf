{%- set aws = values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' -%}
{%- set azure = values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' -%}
{%- set gcp = values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' -%}
{%- set datadog = values.monitoring_solution == 'datadog' -%}
{%- set newrelic = values.monitoring_solution == 'new-relic' -%}
{%- set elastic = values.monitoring_solution == 'elastic-stack' -%}
{%- if aws -%}
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}
{%- endif %}
{%- if azure %}
{% if aws %}
{% endif -%}
# The subscription and identity come from the ARM_* environment variables or
# from `az login` together with ARM_SUBSCRIPTION_ID.
provider "azurerm" {
  features {
    # Storage accounts and vaults deny public network access, so the provider
    # must not use their data plane.
    storage {
      data_plane_available = false
    }

    # Keys and secrets are created through deployments that cannot delete
    # them again; the vault's removal takes care of them.
    template_deployment {
      delete_nested_items_during_deletion = false
    }
  }
}
{%- if datadog or newrelic %}

provider "azuread" {}
{%- endif %}
{%- endif %}
{%- if gcp %}
{% if aws or azure %}
{% endif -%}
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
{%- endif %}
{%- if datadog %}

# The API and application keys come from DD_API_KEY and DD_APP_KEY.
provider "datadog" {
  api_url = "https://api.${var.datadog_site}/"
}
{%- endif %}
{%- if newrelic %}

# The API key and account come from NEW_RELIC_API_KEY and NEW_RELIC_ACCOUNT_ID.
provider "newrelic" {
  region = var.newrelic_region
}
{%- endif %}
{%- if elastic %}

# The API key comes from EC_API_KEY.
provider "ec" {}
{%- endif %}
