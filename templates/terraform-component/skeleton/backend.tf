{%- set base = values.componentType ~ "/" ~ values.provider if values.stateFileStructure == "hierarchical" else values.componentType ~ "-" ~ values.provider -%}
{%- set sep = "/" if values.stateFileStructure == "hierarchical" else "-" -%}
{%- set with_env = not values.separateWorkspaces -%}
{%- set state_path = base ~ sep ~ (values.environment ~ sep if with_env else "") ~ values.name -%}
{%- set state_file = state_path ~ ("/terraform.tfstate" if values.stateFileStructure == "hierarchical" else ".tfstate") -%}
{%- if values.backendType == "remote" -%}
# State in HCP Terraform / Terraform Enterprise. The organization comes from
# the TF_CLOUD_ORGANIZATION environment variable, the token from
# TF_TOKEN_app_terraform_io or `terraform login`.
terraform {
  cloud {
    workspaces {
{%- if values.stateFileStructure == "hierarchical" %}
      project = "${{ values.componentType }}-${{ values.provider }}"
      name    = "${{ values.name }}-${{ values.environment }}"
{%- else %}
      name = "${{ values.componentType }}-${{ values.provider }}-${{ values.environment }}-${{ values.name }}"
{%- endif %}
    }
  }
}
{%- elif values.backendType == "s3" -%}
# State in S3. The bucket and its region are passed to `terraform init` with
# -backend-config; see README.md.
terraform {
  backend "s3" {
    key          = "${{ state_file }}"
    encrypt      = true
    use_lockfile = ${{ values.enableStateLocking | string | lower }}
  }
}
{%- elif values.backendType == "azure" -%}
# State in Azure Blob Storage. The storage account and container are passed
# to `terraform init` with -backend-config; see README.md.
terraform {
  backend "azurerm" {
    key              = "${{ state_file }}"
    use_azuread_auth = true
  }
}
{%- elif values.backendType == "gcs" -%}
# State in Cloud Storage. The bucket is passed to `terraform init` with
# -backend-config; see README.md.
terraform {
  backend "gcs" {
    prefix = "${{ state_path }}"
  }
}
{%- endif %}
