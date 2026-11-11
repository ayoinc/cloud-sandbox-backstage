# The backend is configured from variables: OpenTofu evaluates them during
# `tofu init`, so each environment gets its own state object without
# -backend-config flags. Pass the same -var-file to init, plan and apply.
{%- if values.cloud == 'aws' %}
terraform {
  backend "s3" {
    bucket       = var.state_bucket
    key          = "${var.name}/${var.environment}/tofu.tfstate"
    region       = var.state_region
    encrypt      = true
    use_lockfile = true
  }
}
{%- elif values.cloud == 'azure' %}
terraform {
  backend "azurerm" {
    storage_account_name = var.state_storage_account
    container_name       = var.state_container
    key                  = "${var.name}/${var.environment}/tofu.tfstate"
    use_azuread_auth     = true
  }
}
{%- else %}
terraform {
  backend "gcs" {
    bucket = var.state_bucket
    prefix = "${var.name}/${var.environment}"
  }
}
{%- endif %}
