# =============================================================================
# Production Environment Configuration
# =============================================================================
# - Zone redundant and geo-redundant
# - Resource groups are protected by delete locks
# =============================================================================
{% set fromForm = values.envName == 'prod' -%}

# Project Configuration
name          = "${{ values.name }}"
environment   = "prod"
description   = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner         = "${{ values.owner }}"
business_unit = "${{ values.businessUnit }}"

# Regions
location           = "${{ values.primaryRegion }}"
secondary_location = "${{ values.secondaryRegion }}"

# Modules (the same set in every environment)
enable_networking  = ${{ values.enableNetworking | dump }}
enable_compute     = ${{ values.enableCompute | dump }}
enable_containers  = ${{ values.enableContainers | dump }}
enable_storage     = ${{ values.enableStorage | dump }}
enable_database    = ${{ values.enableDatabase | dump }}
enable_security    = ${{ values.enableSecurity | dump }}
enable_identity    = ${{ values.enableIdentity | dump }}
enable_monitoring  = ${{ values.enableMonitoring | dump }}
enable_integration = ${{ values.enableIntegration | dump }}
enable_governance  = ${{ values.enableGovernance | dump }}

# Resilience and Cost{% if fromForm %} (from the template form){% endif %}
enable_dr                = ${{ (values.enableDR | dump) if fromForm else 'true' }}
enable_high_availability = ${{ (values.enableHighAvailability | dump) if fromForm else 'true' }}
enable_auto_shutdown     = ${{ (values.enableAutoShutdown | dump) if fromForm else 'false' }}
auto_shutdown_time       = "${{ values.autoShutdownTime }}"

# Networking
vnet_address_space = "10.2.0.0/16"

# Containers
kubernetes_version = "1.37"
aks_node_vm_size   = "Standard_D4s_v3"
aks_node_count     = 3
aks_min_node_count = 3
aks_max_node_count = 10

# Database
database_sku_name   = "GP_Standard_D4s_v3"
database_storage_mb = 131072

# Compute
vm_size  = "Standard_D4s_v5"
vm_count = 3

# Monitoring and Governance
log_retention_days = 90
monthly_budget     = 10000
