locals {
  # Common naming prefix
  name_prefix = "${var.project_name}-${var.environment}"

  # Common tags applied to all resources
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "${{ values.name }}"
      Owner       = "${{ values.owner }}"
    },
    var.tags
  )

{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}

  # Azure-specific locals
  azure_resource_group_name = var.azure_resource_group_name != "" ? var.azure_resource_group_name : "${local.name_prefix}-rg"
{%- endif %}

{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}

  # GCP-specific locals
  gcp_labels = {
    for k, v in local.common_tags : lower(replace(k, "/[^a-z0-9_-]/", "_")) => lower(replace(v, "/[^a-z0-9_-]/", "_"))
  }
{%- endif %}
}
