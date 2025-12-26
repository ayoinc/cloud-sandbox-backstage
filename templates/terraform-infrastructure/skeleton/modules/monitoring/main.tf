# Monitoring Module
# Deploys Prometheus + Grafana monitoring stack using Helm

resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = var.namespace
  create_namespace = true
  version          = "56.6.2"

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "${var.metrics_retention_days}d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          }
        }
      }
      grafana = {
        enabled       = var.enable_grafana
        adminPassword = var.grafana_admin_password
        persistence = {
          enabled = true
          size    = var.grafana_storage_size
        }
        ingress = {
          enabled = var.enable_ingress
          hosts   = var.grafana_hosts
        }
      }
      alertmanager = {
        enabled = var.enable_alertmanager
      }
    })
  ]

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
}

# Generate Grafana admin password if not provided
resource "random_password" "grafana" {
  count   = var.grafana_admin_password == "" ? 1 : 0
  length  = 16
  special = true
}

locals {
  grafana_password = var.grafana_admin_password != "" ? var.grafana_admin_password : (
    length(random_password.grafana) > 0 ? random_password.grafana[0].result : ""
  )
}
