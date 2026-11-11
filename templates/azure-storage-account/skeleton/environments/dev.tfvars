# =============================================================================
# Development Environment
# =============================================================================
# Low cost: locally redundant storage and short retention.
# =============================================================================

name        = "${{ values.name }}"
environment = "dev"
location    = "${{ values.location }}"
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

{% set fromForm = values.envName == 'dev' -%}
# Redundancy and tier{% if fromForm %} (from the template form){% endif %}
replication_type = "${{ values.replicationType if fromForm else 'LRS' }}"
access_tier      = "${{ values.accessTier if fromForm else 'Hot' }}"

# Private blob containers
container_names = [
{%- for container in values.containerNames %}
  "${{ container }}",
{%- endfor %}
]

# Data protection
versioning_enabled         = ${{ 'true' if values.versioning else 'false' }}
soft_delete_retention_days = ${{ values.softDeleteDays if fromForm else 7 }}

# Lifecycle: days after the last modification; null switches a step off
cool_after_days                   = 30
archive_after_days                = null
expire_after_days                 = null
noncurrent_version_retention_days = 30

# Network: the firewall denies everything that is not listed here
public_network_access_enabled = false
allowed_ip_ranges             = []
allowed_subnet_ids            = []
private_endpoint_subnet_id    = null
private_dns_zone_id           = null

# Encryption with your own key: { key_vault_id = "...", key_vault_key_id = "..." }
customer_managed_key = null

# Data access (object IDs) and logs
blob_data_contributor_principal_ids = []
blob_data_reader_principal_ids      = []
log_analytics_workspace_id          = null

tags = {
  CostCenter = "development"
}
