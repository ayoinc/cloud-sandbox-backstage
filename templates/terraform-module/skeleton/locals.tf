{%- set aws = values.provider == 'aws' or values.provider == 'multi-cloud' -%}
{%- set azure = values.provider == 'azure' or values.provider == 'multi-cloud' -%}
{%- set gcp = values.provider == 'gcp' or values.provider == 'multi-cloud' -%}
locals {
  # Tags applied to every resource; callers add their own through var.tags.
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "${{ values.name }}"
    },
    var.tags,
  )
{%- if azure %}

  azure_resource_group_name = coalesce(var.azure_resource_group_name, "${var.project_name}-${var.environment}-rg")
{%- endif %}
{%- if gcp %}

  # Google Cloud labels allow only lowercase letters, digits, hyphens and
  # underscores.
  gcp_labels = {
    for key, value in local.common_tags :
    replace(lower(key), "/[^a-z0-9_-]/", "_") => replace(lower(value), "/[^a-z0-9_-]/", "_")
  }
{%- endif %}
}
