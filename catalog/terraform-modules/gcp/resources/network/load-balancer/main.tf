terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

locals {
  resource_name = "${var.project_name}-${var.environment}-${var.name}"
}

# External IP Address
resource "google_compute_global_address" "this" {
  project      = var.project_id
  name         = "${local.resource_name}-ip"
  address_type = "EXTERNAL"
}

# Health Check
resource "google_compute_health_check" "this" {
  project             = var.project_id
  name                = "${local.resource_name}-health-check"
  check_interval_sec  = var.health_check.check_interval_sec
  timeout_sec         = var.health_check.timeout_sec
  healthy_threshold   = var.health_check.healthy_threshold
  unhealthy_threshold = var.health_check.unhealthy_threshold

  http_health_check {
    port         = var.health_check.port
    request_path = var.health_check.request_path
  }
}

# Backend Service
resource "google_compute_backend_service" "this" {
  project                         = var.project_id
  name                            = "${local.resource_name}-backend"
  protocol                        = "HTTP"
  port_name                       = "http"
  timeout_sec                     = 30
  connection_draining_timeout_sec = var.connection_draining_timeout_sec
  health_checks                   = [google_compute_health_check.this.id]
  security_policy                 = var.security_policy
  custom_request_headers          = var.custom_request_headers
  custom_response_headers         = var.custom_response_headers

  dynamic "backend" {
    for_each = var.backends
    content {
      group                 = backend.value.group
      balancing_mode        = backend.value.balancing_mode
      capacity_scaler       = backend.value.capacity_scaler
      max_rate_per_instance = backend.value.max_rate_per_instance
      max_utilization       = backend.value.max_utilization
    }
  }

  dynamic "cdn_policy" {
    for_each = var.enable_cdn ? [1] : []
    content {
      cache_mode                   = var.cdn_cache_mode
      signed_url_cache_max_age_sec = 3600
    }
  }

  enable_cdn = var.enable_cdn

  log_config {
    enable      = var.log_config_enable
    sample_rate = var.log_config_sample_rate
  }
}

# URL Map
resource "google_compute_url_map" "this" {
  project         = var.project_id
  name            = "${local.resource_name}-url-map"
  default_service = google_compute_backend_service.this.id
}

# Managed SSL Certificate
resource "google_compute_managed_ssl_certificate" "this" {
  count   = var.enable_https && length(var.managed_ssl_certificate_domains) > 0 ? 1 : 0
  project = var.project_id
  name    = "${local.resource_name}-cert"

  managed {
    domains = var.managed_ssl_certificate_domains
  }
}

# HTTP Proxy
resource "google_compute_target_http_proxy" "this" {
  count   = var.enable_https ? 0 : 1
  project = var.project_id
  name    = "${local.resource_name}-http-proxy"
  url_map = google_compute_url_map.this.id
}

# HTTPS Proxy
resource "google_compute_target_https_proxy" "this" {
  count   = var.enable_https ? 1 : 0
  project = var.project_id
  name    = "${local.resource_name}-https-proxy"
  url_map = google_compute_url_map.this.id

  ssl_certificates = length(var.ssl_certificates) > 0 ? var.ssl_certificates : (
    length(var.managed_ssl_certificate_domains) > 0 ? [google_compute_managed_ssl_certificate.this[0].id] : []
  )
}

# HTTP Forwarding Rule
resource "google_compute_global_forwarding_rule" "http" {
  count                 = var.enable_https ? 0 : 1
  project               = var.project_id
  name                  = "${local.resource_name}-http-forwarding-rule"
  target                = google_compute_target_http_proxy.this[0].id
  ip_address            = google_compute_global_address.this.address
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
}

# HTTPS Forwarding Rule
resource "google_compute_global_forwarding_rule" "https" {
  count                 = var.enable_https ? 1 : 0
  project               = var.project_id
  name                  = "${local.resource_name}-https-forwarding-rule"
  target                = google_compute_target_https_proxy.this[0].id
  ip_address            = google_compute_global_address.this.address
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
}
