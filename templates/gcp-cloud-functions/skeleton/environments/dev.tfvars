# =============================================================================
# Development Environment
# =============================================================================
# Small instances that scale to zero.
# =============================================================================

name        = "${{ values.name }}"
environment = "dev"
project_id  = "${{ values.gcpProject }}"
region      = "${{ values.region }}"
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

{% set fromForm = values.envName == 'dev' -%}
# Build
runtime     = "${{ values.runtime }}"
entry_point = "handler"
source_dir  = "function"

# Trigger: http or pubsub
trigger_type          = "${{ values.triggerType }}"
allow_unauthenticated = ${{ 'true' if values.allowUnauthenticated else 'false' }}
invokers              = []
ingress_settings      = null

# Runtime{% if fromForm %} (from the template form){% endif %}
available_memory   = "${{ values.memory if fromForm else '256M' }}"
timeout_seconds    = ${{ values.timeoutSeconds }}
min_instance_count = 0
max_instance_count = ${{ values.maxInstances if fromForm else 3 }}

environment_variables = {
  APP_ENVIRONMENT = "dev"
}

# Secrets from Secret Manager: { API_KEY = { secret = "<secret name>", version = "latest" } }
secret_environment_variables = {}

# Project roles of the function's service account, such as "roles/datastore.user"
runtime_service_account_roles = []

enable_apis = true

labels = {
  cost-center = "development"
}
