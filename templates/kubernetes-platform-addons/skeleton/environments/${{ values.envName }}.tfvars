# =============================================================================
# Add-on Configuration of the ${{ values.environment }} cluster
# =============================================================================
# The DNS API token is not set here: the pipeline passes it from a repository
# secret (TF_VAR_dns_api_token).
# =============================================================================

name        = "${{ values.name }}"
environment = "${{ values.envName }}"
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

# Two replicas and pod disruption budgets for every add-on
high_availability = ${{ 'true' if values.envName == 'prod' else 'false' }}

# Ingress controller (Traefik)
enable_ingress              = ${{ 'true' if values.ingressController else 'false' }}
ingress_service_annotations = {}
enable_gateway_api          = false

# cert-manager
enable_cert_manager = ${{ 'true' if values.certManager else 'false' }}
acme_email          = "${{ values.acmeEmail }}"

# ExternalDNS
enable_external_dns = ${{ 'true' if values.externalDns else 'false' }}
dns_provider        = "${{ values.dnsProvider }}"
dns_domain_filters  = [{% if values.dnsDomain %}"${{ values.dnsDomain }}"{% endif %}]
# upsert-only never deletes a record; switch to sync once the records are
# known to belong to this cluster.
dns_policy                      = "upsert-only"
dns_service_account_annotations = {}

# Metrics Server
enable_metrics_server = ${{ 'true' if values.metricsServer else 'false' }}
