output "load_balancer_ip" {
  description = "The external IP address of the load balancer"
  value       = google_compute_global_address.this.address
}

output "backend_service_id" {
  description = "The ID of the backend service"
  value       = google_compute_backend_service.this.id
}

output "url_map_id" {
  description = "The ID of the URL map"
  value       = google_compute_url_map.this.id
}

output "http_proxy_id" {
  description = "The ID of the HTTP proxy (null if HTTPS is enabled)"
  value       = var.enable_https ? null : google_compute_target_http_proxy.this[0].id
}

output "https_proxy_id" {
  description = "The ID of the HTTPS proxy (null if HTTPS is disabled)"
  value       = var.enable_https ? google_compute_target_https_proxy.this[0].id : null
}

output "forwarding_rule_id" {
  description = "The ID of the forwarding rule"
  value       = var.enable_https ? google_compute_global_forwarding_rule.https[0].id : google_compute_global_forwarding_rule.http[0].id
}

output "ssl_certificate_ids" {
  description = "The IDs of the managed SSL certificates"
  value       = var.enable_https && length(var.managed_ssl_certificate_domains) > 0 ? [google_compute_managed_ssl_certificate.this[0].id] : []
}
