# -----------------------------------------------------------------------------
# Web tier: global external Application Load Balancer. HTTP is redirected to
# HTTPS. Cloud Armor and Cloud CDN are attached to the backend service when
# enabled.
# -----------------------------------------------------------------------------

locals {
  # Name GKE gives the network endpoint groups of the application's Service
  # when the Service carries the annotation shown in the documentation.
  gke_neg_name = "${local.name_prefix}-app"
}

resource "google_compute_global_address" "load_balancer" {
  name        = "${local.name_prefix}-lb"
  description = "Public address of the load balancer"

  depends_on = [google_project_service.required]
}

# On GKE the endpoints are pods, checked on the port they serve. Instances are
# checked on the application port; the instance group uses the same check to
# replace instances that stop answering.
resource "google_compute_health_check" "app" {
  name                = "${local.name_prefix}-app"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port_specification = local.runs_gke ? "USE_SERVING_PORT" : "USE_FIXED_PORT"
    port               = local.runs_gke ? null : var.container_port
    request_path       = var.health_check_path
  }

  log_config {
    enable = true
  }

  depends_on = [google_project_service.required]
}

# Network endpoint groups GKE created for the application's Service, one per
# zone listed in gke_neg_zones.
data "google_compute_network_endpoint_group" "app" {
  for_each = toset(local.runs_gke ? var.gke_neg_zones : [])

  name = local.gke_neg_name
  zone = each.value
}

resource "google_compute_backend_service" "app" {
  name                  = "${local.name_prefix}-app"
  description           = "Application tier of ${var.project_name} (${var.environment})"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"
  port_name             = local.runs_instances ? "http" : null
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.app.id]

  connection_draining_timeout_sec = 60

  security_policy = one(google_compute_security_policy.edge[*].id)

  enable_cdn = var.enable_cloud_cdn

  dynamic "cdn_policy" {
    for_each = var.enable_cloud_cdn ? [1] : []

    content {
      cache_mode        = "CACHE_ALL_STATIC"
      default_ttl       = 3600
      client_ttl        = 3600
      max_ttl           = 86400
      serve_while_stale = 86400

      cache_key_policy {
        include_host         = true
        include_protocol     = true
        include_query_string = true
      }
    }
  }

  dynamic "backend" {
    for_each = google_compute_region_instance_group_manager.app

    content {
      group           = backend.value.instance_group
      balancing_mode  = "UTILIZATION"
      max_utilization = 0.8
      capacity_scaler = 1.0
    }
  }

  dynamic "backend" {
    for_each = data.google_compute_network_endpoint_group.app

    content {
      group                 = backend.value.id
      balancing_mode        = "RATE"
      max_rate_per_endpoint = 100
      capacity_scaler       = 1.0
    }
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_url_map" "app" {
  name            = "${local.name_prefix}-app"
  description     = "Sends every request to the application"
  default_service = google_compute_backend_service.app.id
}

# --- Certificate ---------------------------------------------------------------

# Used until domain names for a Google-managed certificate are supplied in domains.
resource "tls_private_key" "self_signed" {
  count = length(var.domains) == 0 ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "self_signed" {
  count = length(var.domains) == 0 ? 1 : 0

  private_key_pem       = tls_private_key.self_signed[0].private_key_pem
  validity_period_hours = 8760
  early_renewal_hours   = 720

  subject {
    common_name  = "${local.name_prefix}.internal"
    organization = var.project_name
  }

  allowed_uses = ["key_encipherment", "digital_signature", "server_auth"]
}

resource "google_compute_ssl_certificate" "self_signed" {
  count = length(var.domains) == 0 ? 1 : 0

  name_prefix = "${local.name_prefix}-self-"
  description = "Self-signed certificate used until domains is set"
  private_key = tls_private_key.self_signed[0].private_key_pem
  certificate = tls_self_signed_cert.self_signed[0].cert_pem

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_project_service.required]
}

resource "google_compute_managed_ssl_certificate" "domains" {
  count = length(var.domains) > 0 ? 1 : 0

  name = "${local.name_prefix}-cert-${substr(sha1(join(",", var.domains)), 0, 8)}"

  managed {
    domains = var.domains
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_project_service.required]
}

resource "google_compute_ssl_policy" "modern" {
  name            = "${local.name_prefix}-tls"
  description     = "TLS 1.2 or newer with modern cipher suites"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"

  depends_on = [google_project_service.required]
}

# --- HTTPS listener ------------------------------------------------------------

resource "google_compute_target_https_proxy" "app" {
  name       = "${local.name_prefix}-https"
  url_map    = google_compute_url_map.app.id
  ssl_policy = google_compute_ssl_policy.modern.id

  ssl_certificates = concat(
    google_compute_ssl_certificate.self_signed[*].id,
    google_compute_managed_ssl_certificate.domains[*].id,
  )
}

resource "google_compute_global_forwarding_rule" "https" {
  name                  = "${local.name_prefix}-https"
  description           = "HTTPS from the internet"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.load_balancer.id
  port_range            = "443"
  target                = google_compute_target_https_proxy.app.id
}

# --- HTTP listener: redirect to HTTPS ------------------------------------------

resource "google_compute_url_map" "https_redirect" {
  name        = "${local.name_prefix}-https-redirect"
  description = "Redirects HTTP requests to HTTPS"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }

  depends_on = [google_project_service.required]
}

resource "google_compute_target_http_proxy" "https_redirect" {
  name    = "${local.name_prefix}-http"
  url_map = google_compute_url_map.https_redirect.id
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${local.name_prefix}-http"
  description           = "HTTP from the internet, redirected to HTTPS"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.load_balancer.id
  port_range            = "80"
  target                = google_compute_target_http_proxy.https_redirect.id
}

# --- Cloud Armor (enable_cloud_armor) ------------------------------------------

resource "google_compute_security_policy" "edge" {
  count = var.enable_cloud_armor ? 1 : 0

  name        = "${local.name_prefix}-armor"
  description = "Web application firewall and rate limit for ${var.project_name} (${var.environment})"
  type        = "CLOUD_ARMOR"

  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }

  rule {
    description = "Block SQL injection"
    action      = "deny(403)"
    priority    = 1000

    match {
      expr {
        expression = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 1})"
      }
    }
  }

  rule {
    description = "Block cross-site scripting"
    action      = "deny(403)"
    priority    = 1100

    match {
      expr {
        expression = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': 1})"
      }
    }
  }

  rule {
    description = "Block local file inclusion"
    action      = "deny(403)"
    priority    = 1200

    match {
      expr {
        expression = "evaluatePreconfiguredWaf('lfi-v33-stable', {'sensitivity': 1})"
      }
    }
  }

  rule {
    description = "Block remote code execution"
    action      = "deny(403)"
    priority    = 1300

    match {
      expr {
        expression = "evaluatePreconfiguredWaf('rce-v33-stable', {'sensitivity': 1})"
      }
    }
  }

  rule {
    description = "Throttle addresses that send more than rate_limit_per_minute requests a minute"
    action      = "throttle"
    priority    = 2000

    match {
      versioned_expr = "SRC_IPS_V1"

      config {
        src_ip_ranges = ["*"]
      }
    }

    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"

      rate_limit_threshold {
        count        = var.rate_limit_per_minute
        interval_sec = 60
      }
    }
  }

  rule {
    description = "Allow everything else"
    action      = "allow"
    priority    = 2147483647

    match {
      versioned_expr = "SRC_IPS_V1"

      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  depends_on = [google_project_service.required]
}
