# Monitoring Module Outputs

output "prometheus_endpoint" {
  description = "Prometheus server endpoint"
  value       = "http://prometheus-kube-prometheus-prometheus.${var.namespace}.svc.cluster.local:9090"
}

output "grafana_endpoint" {
  description = "Grafana dashboard endpoint"
  value       = var.enable_grafana ? "http://prometheus-grafana.${var.namespace}.svc.cluster.local:80" : null
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = local.grafana_password
  sensitive   = true
}

output "alertmanager_endpoint" {
  description = "Alertmanager endpoint"
  value       = var.enable_alertmanager ? "http://prometheus-kube-prometheus-alertmanager.${var.namespace}.svc.cluster.local:9093" : null
}

output "namespace" {
  description = "Monitoring namespace"
  value       = var.namespace
}
