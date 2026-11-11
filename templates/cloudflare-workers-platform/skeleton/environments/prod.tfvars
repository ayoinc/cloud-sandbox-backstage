# =============================================================================
# Production Environment Configuration
# =============================================================================
# A tenth of the requests is logged to keep log volume in check.
# The account ID and the API token are not set here: the pipeline passes them
# from repository secrets (TF_VAR_account_id, CLOUDFLARE_API_TOKEN).
# =============================================================================

name        = "${{ values.name }}"
environment = "prod"

# Storage
data_store  = "${{ values.dataStore }}"
r2_location = "${{ values.r2Location }}"

{% set fromForm = values.envName == 'prod' -%}
# Routing{% if fromForm and values.customHostname %} (custom domain from the template form){% endif %}
custom_hostname     = "${{ values.customHostname if fromForm else '' }}"
routes              = []
workers_dev_enabled = ${{ 'false' if fromForm and values.customHostname else 'true' }}

# Runtime
compatibility_date = "2026-11-01"
log_sampling_rate  = 0.1
