# =============================================================================
# Zone Configuration
# =============================================================================
# The account ID and the API token are not set here: the pipeline passes them
# from repository secrets (TF_VAR_account_id, CLOUDFLARE_API_TOKEN).
# =============================================================================

zone_name   = "${{ values.domain }}"
{%- if values.existingZoneId %}
zone_id     = "${{ values.existingZoneId }}"
{%- endif %}
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

# TLS
ssl_mode        = "${{ values.sslMode }}"
min_tls_version = "${{ values.minTlsVersion }}"
hsts = {
  enabled = true
  max_age = 31536000
  # Turn these on once every subdomain serves HTTPS; preload is hard to undo.
  include_subdomains = false
  preload            = false
}

# DNS
enable_dnssec = true
dns_records = {
{%- if values.originIpv4 %}
  apex = {
    name    = "${{ values.domain }}"
    type    = "A"
    content = "${{ values.originIpv4 }}"
    proxied = true
  }
  www = {
    name    = "www.${{ values.domain }}"
    type    = "CNAME"
    content = "${{ values.domain }}"
    proxied = true
  }
{%- endif %}
}

# WAF: the managed rulesets need a paid plan (this zone: ${{ values.plan }})
enable_managed_waf = ${{ 'false' if values.plan == 'free' else 'true' }}

rate_limit = {
  enabled             = ${{ 'true' if values.rateLimiting else 'false' }}
  expression          = "(http.request.uri.path contains \"/login\") or (http.request.uri.path contains \"/signin\")"
  requests_per_period = 20
  period              = 10
  mitigation_timeout  = 10
}
