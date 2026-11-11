# =============================================================================
# Cloudflare Zone - Zone, TLS settings and DNS
# =============================================================================

locals {
  zone_id         = var.zone_id != null ? var.zone_id : cloudflare_zone.this[0].id
  managed_comment = "Managed by Terraform. Owner: ${var.owner}"

  # Settings whose value is a plain string. HSTS is an object and has its own
  # resource below.
  zone_settings = {
    ssl                      = var.ssl_mode
    min_tls_version          = var.min_tls_version
    tls_1_3                  = "on"
    always_use_https         = "on"
    automatic_https_rewrites = "on"
    opportunistic_encryption = "on"
    http3                    = "on"
    # 0-RTT trades replay protection for speed; keep it off.
    "0rtt"         = "off"
    security_level = var.security_level
    browser_check  = "on"
    ipv6           = "on"
  }
}

resource "cloudflare_zone" "this" {
  count = var.zone_id == null ? 1 : 0

  account = {
    id = var.account_id
  }
  name = var.zone_name
  type = "full"
}

resource "cloudflare_zone_setting" "this" {
  for_each = local.zone_settings

  zone_id    = local.zone_id
  setting_id = each.key
  value      = each.value
}

resource "cloudflare_zone_setting" "hsts" {
  zone_id    = local.zone_id
  setting_id = "security_header"
  value = {
    strict_transport_security = {
      enabled            = var.hsts.enabled
      max_age            = var.hsts.max_age
      include_subdomains = var.hsts.include_subdomains
      preload            = var.hsts.preload
      nosniff            = true
    }
  }
}

resource "cloudflare_zone_dnssec" "this" {
  count = var.enable_dnssec ? 1 : 0

  zone_id = local.zone_id
  status  = "active"
}

resource "cloudflare_dns_record" "this" {
  for_each = var.dns_records

  zone_id  = local.zone_id
  name     = each.value.name
  type     = each.value.type
  content  = each.value.content
  priority = each.value.priority
  proxied  = each.value.proxied
  # Proxied records always use the automatic TTL, which the API expresses as 1.
  ttl     = each.value.proxied ? 1 : each.value.ttl
  comment = local.managed_comment
}

# Only the listed certificate authorities may issue for the zone. Cloudflare
# adds the records its own edge certificates need.
resource "cloudflare_dns_record" "caa" {
  for_each = toset(var.caa_issuers)

  zone_id = local.zone_id
  name    = var.zone_name
  type    = "CAA"
  ttl     = 3600
  data = {
    flags = 0
    tag   = "issue"
    value = each.value
  }
  comment = local.managed_comment
}
