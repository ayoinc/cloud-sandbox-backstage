# =============================================================================
# Staging Environment
# =============================================================================
# Production-like compute without a standby.
# =============================================================================

name        = "${{ values.name }}"
environment = "staging"
location    = "${{ values.location }}"
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

{% set fromForm = values.envName == 'staging' -%}
# Server{% if fromForm %} (from the template form){% endif %}
postgresql_version     = "${{ values.postgresVersion }}"
sku_name               = "${{ values.skuName if fromForm else 'GP_Standard_D2ds_v5' }}"
storage_gb             = ${{ values.storageGb if fromForm else 64 }}
high_availability_mode = "${{ values.highAvailability if fromForm else 'Disabled' }}"

# Backups
backup_retention_days        = 14
geo_redundant_backup_enabled = false

# Weekly patch window in UTC (0 is Sunday)
maintenance_window = {
  day_of_week  = 0
  start_hour   = 3
  start_minute = 0
}

server_parameters = {
  "connection_throttle.enable" = "on"
  "log_checkpoints"            = "on"
}

database_names = ["${{ values.databaseName }}"]

# Entra ID administrators: password authentication is disabled
entra_administrators = [
  {
    object_id      = "${{ values.entraAdminObjectId }}"
    principal_name = ${{ values.entraAdminName | dump | replace('${', '$${') | replace('%{', '%%{') }}
    principal_type = "${{ values.entraAdminType }}"
  },
]

# Network: a new virtual network, or an existing delegated subnet and zone
virtual_network_address_space = "10.60.1.0/24"
delegated_subnet_id           = null
private_dns_zone_id           = null

# Logs and metrics destination
log_analytics_workspace_id = null

tags = {
  CostCenter = "staging"
}
