# =============================================================================
# Development Environment Configuration
# =============================================================================
# Served on workers.dev unless a custom domain is set; every request is logged.
# The account ID and the API token are not set here: the pipeline passes them
# from repository secrets (TF_VAR_account_id, CLOUDFLARE_API_TOKEN).
# =============================================================================

name        = "${{ values.name }}"
environment = "dev"

# Storage
data_store  = "${{ values.dataStore }}"
r2_location = "${{ values.r2Location }}"

{% set fromForm = values.envName == 'dev' -%}
# Routing{% if fromForm and values.customHostname %} (custom domain from the template form){% endif %}
custom_hostname     = "${{ values.customHostname if fromForm else '' }}"
routes              = []
workers_dev_enabled = ${{ 'false' if fromForm and values.customHostname else 'true' }}

# Runtime
compatibility_date = "2026-11-01"
log_sampling_rate  = 1
