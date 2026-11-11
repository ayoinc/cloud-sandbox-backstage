# =============================================================================
# Development Environment
# =============================================================================
# Short soft delete retention so names free up quickly.
# =============================================================================

name        = "${{ values.name }}"
environment = "dev"
location    = "${{ values.location }}"
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

{% set fromForm = values.envName == 'dev' -%}
# Vault{% if fromForm %} (from the template form){% endif %}
sku_name                   = "${{ values.skuName if fromForm else 'standard' }}"
soft_delete_retention_days = ${{ values.softDeleteDays if fromForm else 7 }}

# Azure services that read from the vault on their own behalf
enabled_for_disk_encryption     = false
enabled_for_deployment          = false
enabled_for_template_deployment = false

# Network: the firewall denies everything that is not listed here
public_network_access_enabled = ${{ 'true' if values.publicNetworkAccess else 'false' }}
allowed_ip_ranges             = []
allowed_subnet_ids            = []
trusted_services_bypass       = true
private_endpoint_subnet_id    = null
private_dns_zone_id           = null

# Data plane access: object IDs of users, groups and managed identities
administrator_principal_ids        = []
secrets_officer_principal_ids      = []
secrets_user_principal_ids         = []
crypto_user_principal_ids          = []
certificates_officer_principal_ids = []

# Audit log destination
log_analytics_workspace_id = null

tags = {
  CostCenter = "development"
}
