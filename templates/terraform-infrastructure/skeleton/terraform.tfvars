{%- set aws = values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' -%}
{%- set azure = values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' -%}
{%- set gcp = values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' -%}
{%- set datadog = values.monitoring_solution == 'datadog' -%}
{%- set newrelic = values.monitoring_solution == 'new-relic' -%}
{%- set elastic = values.monitoring_solution == 'elastic-stack' -%}
# Settings chosen when this stack was created; they apply to every
# environment. Environment-specific settings are in environments/<name>.tfvars
# and take precedence. Change values here and push to apply the change.
name                = "${{ values.name }}"
owner               = "${{ values.owner }}"
infrastructure_type = "${{ values.infrastructure_type }}"
{%- if aws %}

aws_region           = "${{ values.region }}"
aws_secondary_region = "${{ "us-east-1" if values.region == "us-west-2" else "us-west-2" }}"
{%- endif %}
{%- if azure %}

azure_location           = "${{ values.azure_location }}"
azure_secondary_location = "${{ "eastus2" if values.azure_location == "centralus" else "centralus" }}"
{%- endif %}
{%- if gcp %}

gcp_region           = "${{ values.gcp_region }}"
gcp_secondary_region = "${{ "us-central1" if values.gcp_region == "us-east1" else "us-east1" }}"
{%- endif %}

# Network
enable_networking           = ${{ values.enable_networking | string | lower }}
enable_security_group_rules = ${{ values.enable_security_group_rules | string | lower }}

# Kubernetes
enable_kubernetes  = ${{ values.enable_kubernetes | string | lower }}
{%- if values.kubernetes_version and values.kubernetes_version != "default" %}
kubernetes_version = "${{ values.kubernetes_version }}"
{%- endif %}
node_size          = "${{ values.node_instance_type }}"
enable_autoscaling = ${{ values.enable_autoscaling | string | lower }}
min_nodes          = ${{ values.min_nodes }}
max_nodes          = ${{ values.max_nodes }}

# Data
enable_database = ${{ values.enable_database | string | lower }}
database_type   = "${{ values.database_type }}"
enable_storage  = ${{ values.enable_storage | string | lower }}
enable_cdn      = ${{ values.enable_cdn | string | lower }}

# Security and compliance
enable_waf             = ${{ values.enable_waf | string | lower }}
enable_secrets_manager = ${{ values.enable_secrets_manager | string | lower }}
enable_kms             = ${{ values.enable_kms | string | lower }}
enable_backup          = ${{ values.enable_backup | string | lower }}
compliance_framework   = "${{ values.compliance_framework }}"

# Monitoring
enable_monitoring   = ${{ values.enable_monitoring | string | lower }}
monitoring_solution = "${{ values.monitoring_solution }}"
enable_alerting     = ${{ values.enable_alerting | string | lower }}
log_retention_days  = ${{ values.log_retention_days }}

# Resilience and cost
enable_disaster_recovery = ${{ values.enable_disaster_recovery | string | lower }}
enable_cost_optimization = ${{ values.enable_cost_optimization | string | lower }}
