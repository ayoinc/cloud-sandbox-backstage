# =============================================================================
# Development Environment
# =============================================================================
# Low cost: scales to zero and keeps logs briefly.
# =============================================================================

name        = "${{ values.name }}"
environment = "dev"
location    = "${{ values.location }}"
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

{% set fromForm = values.envName == 'dev' -%}
# Container{% if fromForm %} (from the template form){% endif %}
container_image  = "${{ values.containerImage }}"
container_cpu    = ${{ values.cpu if fromForm else '0.25' }}
container_memory = "${{ values.memory if fromForm else '0.5Gi' }}"

environment_variables = {
  APP_ENVIRONMENT = "dev"
}

# Secrets from Key Vault: { DATABASE_PASSWORD = "https://<vault>.vault.azure.net/secrets/<name>" }
secret_environment_variables = {}
key_vault_id                 = null

# Private registry: { id = "<registry resource ID>", login_server = "<name>.azurecr.io" }
container_registry = null

# Scaling{% if fromForm %} (from the template form){% endif %}
min_replicas                    = ${{ values.minReplicas if fromForm else 0 }}
max_replicas                    = ${{ ([values.minReplicas, values.maxReplicas] | sort | last) if fromForm else 2 }}
concurrent_requests_per_replica = 50

# Ingress
target_port              = ${{ values.targetPort }}
external_ingress_enabled = ${{ 'true' if values.externalIngress else 'false' }}
health_probe_path        = "/"

# Environment network: null uses a network managed by Azure
infrastructure_subnet_id       = null
internal_load_balancer_enabled = false
zone_redundancy_enabled        = false

log_retention_days = 30

tags = {
  CostCenter = "development"
}
