# =============================================================================
# Cloudflare Zone - WAF, rate limiting and response headers
# =============================================================================
# A zone has one entry point ruleset per phase. If the zone already has rules
# in one of these phases, import that ruleset before the first apply:
#   terraform import cloudflare_ruleset.<name> zones/<zone_id>/<ruleset_id>
# =============================================================================

locals {
  # IDs of the rulesets Cloudflare publishes; they are the same in every account.
  cloudflare_managed_ruleset_id = "efb7b8c949ac4650a09736fc376e9aee"
  owasp_core_ruleset_id         = "4814384a9e5d4991b9815dcfc25d2f1f"
}

resource "cloudflare_ruleset" "custom_firewall" {
  count = length(var.firewall_rules) > 0 ? 1 : 0

  zone_id     = local.zone_id
  name        = "Custom firewall rules"
  description = "Custom rules of ${var.zone_name}. ${var.description}"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules = [
    for rule in var.firewall_rules : {
      ref         = rule.ref
      description = rule.description
      expression  = rule.expression
      action      = rule.action
      enabled     = rule.enabled
    }
  ]
}

resource "cloudflare_ruleset" "managed_waf" {
  count = var.enable_managed_waf ? 1 : 0

  zone_id     = local.zone_id
  name        = "Managed WAF"
  description = "Cloudflare Managed and OWASP Core rulesets for ${var.zone_name}"
  kind        = "zone"
  phase       = "http_request_firewall_managed"

  rules = [
    {
      ref         = "cloudflare_managed"
      description = "Cloudflare Managed Ruleset"
      expression  = "true"
      action      = "execute"
      action_parameters = {
        id = local.cloudflare_managed_ruleset_id
      }
    },
    {
      ref         = "owasp_core"
      description = "Cloudflare OWASP Core Ruleset"
      expression  = "true"
      action      = "execute"
      action_parameters = {
        id = local.owasp_core_ruleset_id
      }
    },
  ]
}

resource "cloudflare_ruleset" "rate_limit" {
  count = var.rate_limit.enabled ? 1 : 0

  zone_id     = local.zone_id
  name        = "Rate limiting"
  description = "Rate limiting rules of ${var.zone_name}"
  kind        = "zone"
  phase       = "http_ratelimit"

  rules = [
    {
      ref         = "rate_limit"
      description = "Block clients that exceed the request rate"
      expression  = var.rate_limit.expression
      action      = "block"
      ratelimit = {
        characteristics     = ["cf.colo.id", "ip.src"]
        period              = var.rate_limit.period
        requests_per_period = var.rate_limit.requests_per_period
        mitigation_timeout  = var.rate_limit.mitigation_timeout
      }
    },
  ]
}

resource "cloudflare_ruleset" "security_headers" {
  count = length(var.security_headers) > 0 ? 1 : 0

  zone_id     = local.zone_id
  name        = "Security response headers"
  description = "Response headers set on every response of ${var.zone_name}"
  kind        = "zone"
  phase       = "http_response_headers_transform"

  rules = [
    {
      ref         = "security_headers"
      description = "Set security response headers"
      expression  = "true"
      action      = "rewrite"
      action_parameters = {
        headers = {
          for name, value in var.security_headers : name => {
            operation = "set"
            value     = value
          }
        }
      }
    },
  ]
}
