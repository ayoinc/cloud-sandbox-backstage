locals {
  cdn_origin_host = var.enable_cdn ? "${google_storage_bucket.this["assets"].name}.storage.googleapis.com" : null

  # Preconfigured Cloud Armor rule sets (OWASP Core Rule Set 3.3 and the
  # rules for known CVEs), each evaluated at the least strict sensitivity.
  waf_rule_sets = [
    "sqli-v33-stable",
    "xss-v33-stable",
    "lfi-v33-stable",
    "rfi-v33-stable",
    "rce-v33-stable",
    "scannerdetection-v33-stable",
    "protocolattack-v33-stable",
    "sessionfixation-v33-stable",
    "cve-canary",
  ]
}

# -----------------------------------------------------------------------------
# Cloud Armor
# -----------------------------------------------------------------------------

resource "google_compute_security_policy" "this" {
  count = var.enable_waf ? 1 : 0

  project     = var.project_id
  name        = "${var.name_prefix}-waf"
  description = "Managed web application firewall rules of ${var.name_prefix}"
  type        = "CLOUD_ARMOR"

  dynamic "rule" {
    for_each = local.waf_rule_sets

    content {
      action      = "deny(403)"
      priority    = 1000 + rule.key * 10
      description = "Preconfigured rule set ${rule.value}"

      match {
        expr {
          expression = "evaluatePreconfiguredWaf('${rule.value}', {'sensitivity': 1})"
        }
      }
    }
  }

  rule {
    action      = "allow"
    priority    = 2147483647
    description = "Default rule: allow what the rule sets did not block"

    match {
      versioned_expr = "SRC_IPS_V1"

      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }

  advanced_options_config {
    json_parsing = "STANDARD"
    log_level    = "NORMAL"
  }

  depends_on = [time_sleep.api_propagation]
}

# -----------------------------------------------------------------------------
# Cloud CDN in front of the private assets bucket
# -----------------------------------------------------------------------------

# The load balancer reads the bucket as this service account, so the bucket
# needs no public access and cannot be read around the CDN.
resource "google_service_account" "cdn_origin" {
  count = var.enable_cdn ? 1 : 0

  project      = var.project_id
  account_id   = "${var.name_prefix}-cdn"
  display_name = "CDN origin access of ${var.name_prefix}"

  depends_on = [time_sleep.api_propagation]
}

resource "google_storage_bucket_iam_member" "cdn_origin" {
  count = var.enable_cdn ? 1 : 0

  bucket = google_storage_bucket.this["assets"].name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.cdn_origin[0].email}"
}

# The secret of this key is kept in the Terraform state.
resource "google_storage_hmac_key" "cdn_origin" {
  count = var.enable_cdn ? 1 : 0

  project               = var.project_id
  service_account_email = google_service_account.cdn_origin[0].email
}

resource "google_compute_global_network_endpoint_group" "cdn_origin" {
  count = var.enable_cdn ? 1 : 0

  project               = var.project_id
  name                  = "${var.name_prefix}-cdn-origin"
  description           = "Cloud Storage endpoint of the assets bucket"
  network_endpoint_type = "INTERNET_FQDN_PORT"
  default_port          = 443

  depends_on = [time_sleep.api_propagation]
}

resource "google_compute_global_network_endpoint" "cdn_origin" {
  count = var.enable_cdn ? 1 : 0

  project                       = var.project_id
  global_network_endpoint_group = google_compute_global_network_endpoint_group.cdn_origin[0].name
  fqdn                          = local.cdn_origin_host
  port                          = 443
}

resource "google_compute_backend_service" "cdn" {
  count = var.enable_cdn ? 1 : 0

  project               = var.project_id
  name                  = "${var.name_prefix}-cdn"
  description           = "Assets bucket of ${var.name_prefix} behind Cloud CDN"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"
  enable_cdn            = true
  compression_mode      = "AUTOMATIC"
  security_policy       = var.enable_waf ? google_compute_security_policy.this[0].id : null

  # Cloud Storage selects the bucket by this host name.
  custom_request_headers = ["Host: ${local.cdn_origin_host}"]

  backend {
    group = google_compute_global_network_endpoint_group.cdn_origin[0].id
  }

  # Responses to signed origin requests are private by default, so caching
  # is forced.
  cdn_policy {
    cache_mode        = "FORCE_CACHE_ALL"
    default_ttl       = 3600
    client_ttl        = 3600
    negative_caching  = true
    serve_while_stale = 86400

    # Objects are the same for every query string.
    cache_key_policy {
      include_host         = true
      include_protocol     = true
      include_query_string = false
    }
  }

  # Requests to the origin are signed with the HMAC key (AWS Signature V4,
  # which Cloud Storage accepts).
  security_settings {
    aws_v4_authentication {
      access_key_id      = google_storage_hmac_key.cdn_origin[0].access_id
      access_key         = google_storage_hmac_key.cdn_origin[0].secret
      access_key_version = "v1"
      origin_region      = var.region
    }
  }

  log_config {
    enable      = var.enable_monitoring
    sample_rate = var.enable_monitoring ? 1 : null
  }

  depends_on = [
    google_compute_global_network_endpoint.cdn_origin,
    google_storage_bucket_iam_member.cdn_origin,
  ]
}

resource "google_compute_global_address" "cdn" {
  count = var.enable_cdn ? 1 : 0

  project     = var.project_id
  name        = "${var.name_prefix}-cdn"
  description = "Address of the CDN endpoint"

  depends_on = [time_sleep.api_propagation]
}

resource "google_compute_url_map" "cdn" {
  count = var.enable_cdn ? 1 : 0

  project         = var.project_id
  name            = "${var.name_prefix}-cdn"
  description     = "Routes every request to the assets bucket"
  default_service = google_compute_backend_service.cdn[0].id
}

# Port 80 only redirects to HTTPS.
resource "google_compute_url_map" "cdn_redirect" {
  count = var.enable_cdn ? 1 : 0

  project     = var.project_id
  name        = "${var.name_prefix}-cdn-redirect"
  description = "Redirects HTTP to HTTPS"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }

  depends_on = [time_sleep.api_propagation]
}

resource "google_compute_ssl_policy" "cdn" {
  count = var.enable_cdn ? 1 : 0

  project         = var.project_id
  name            = "${var.name_prefix}-cdn"
  description     = "TLS 1.2 or newer with modern ciphers"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"

  depends_on = [time_sleep.api_propagation]
}

# With a domain, Google issues and renews the certificate once the domain
# resolves to the CDN address.
resource "google_compute_managed_ssl_certificate" "cdn" {
  count = var.enable_cdn && var.cdn_domain != null ? 1 : 0

  project     = var.project_id
  name        = "${var.name_prefix}-cdn"
  description = "Certificate of ${var.cdn_domain}"

  managed {
    domains = [var.cdn_domain]
  }

  depends_on = [time_sleep.api_propagation]
}

# Without a domain no public certificate authority can issue a certificate,
# so the endpoint presents a self-signed one for its IP address: traffic is
# encrypted, but clients must be told to trust it. Set cdn_domain for a
# trusted certificate. The private key is kept in the Terraform state.
resource "tls_private_key" "cdn" {
  count = var.enable_cdn && var.cdn_domain == null ? 1 : 0

  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "cdn" {
  count = var.enable_cdn && var.cdn_domain == null ? 1 : 0

  private_key_pem       = tls_private_key.cdn[0].private_key_pem
  ip_addresses          = [google_compute_global_address.cdn[0].address]
  validity_period_hours = 8760
  early_renewal_hours   = 720
  allowed_uses          = ["digital_signature", "key_encipherment", "server_auth"]

  subject {
    common_name  = google_compute_global_address.cdn[0].address
    organization = var.name_prefix
  }
}

resource "google_compute_ssl_certificate" "cdn" {
  count = var.enable_cdn && var.cdn_domain == null ? 1 : 0

  project     = var.project_id
  name_prefix = "${var.name_prefix}-cdn-"
  description = "Self-signed certificate of the CDN address"
  private_key = tls_private_key.cdn[0].private_key_pem
  certificate = tls_self_signed_cert.cdn[0].cert_pem

  # The renewed certificate must exist before the proxy lets go of the old one.
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_target_https_proxy" "cdn" {
  count = var.enable_cdn ? 1 : 0

  project     = var.project_id
  name        = "${var.name_prefix}-cdn"
  description = "HTTPS front end of the CDN"
  url_map     = google_compute_url_map.cdn[0].id
  ssl_policy  = google_compute_ssl_policy.cdn[0].id
  ssl_certificates = [
    var.cdn_domain != null ? google_compute_managed_ssl_certificate.cdn[0].id : google_compute_ssl_certificate.cdn[0].id,
  ]
}

resource "google_compute_target_http_proxy" "cdn_redirect" {
  count = var.enable_cdn ? 1 : 0

  project     = var.project_id
  name        = "${var.name_prefix}-cdn-redirect"
  description = "HTTP front end that redirects to HTTPS"
  url_map     = google_compute_url_map.cdn_redirect[0].id
}

resource "google_compute_global_forwarding_rule" "cdn_https" {
  count = var.enable_cdn ? 1 : 0

  project               = var.project_id
  name                  = "${var.name_prefix}-cdn-https"
  description           = "HTTPS to the CDN"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.cdn[0].id
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.cdn[0].id
  labels                = local.labels
}

resource "google_compute_global_forwarding_rule" "cdn_http" {
  count = var.enable_cdn ? 1 : 0

  project               = var.project_id
  name                  = "${var.name_prefix}-cdn-http"
  description           = "HTTP to the redirect"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.cdn[0].id
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.cdn_redirect[0].id
  labels                = local.labels
}
