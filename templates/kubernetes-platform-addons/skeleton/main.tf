# =============================================================================
# Kubernetes Platform Add-ons - Namespaces and Helm releases
# =============================================================================

locals {
  replicas = var.high_availability ? 2 : 1

  namespaces = {
    traefik      = var.enable_ingress
    cert-manager = var.enable_cert_manager
    external-dns = var.enable_external_dns
  }

  # Providers that authenticate with an API token, and the environment
  # variable ExternalDNS reads it from.
  dns_token_variables = {
    cloudflare   = "CF_API_TOKEN"
    digitalocean = "DO_TOKEN"
  }
  dns_token_variable = lookup(local.dns_token_variables, var.dns_provider, null)
  dns_uses_token     = var.enable_external_dns && local.dns_token_variable != null
  dns_secret_name    = "external-dns-credentials"
}

resource "kubernetes_namespace_v1" "this" {
  for_each = { for name, enabled in local.namespaces : name => name if enabled }

  metadata {
    name = each.value

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
      # Pod Security Standards: refuse privileged pods, report anything that
      # is not fully restricted.
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }

    annotations = {
      "description" = var.description
      "owner"       = var.owner
    }
  }
}

# -----------------------------------------------------------------------------
# Ingress controller
# -----------------------------------------------------------------------------

resource "helm_release" "traefik" {
  count = var.enable_ingress ? 1 : 0

  name       = "traefik"
  namespace  = kubernetes_namespace_v1.this["traefik"].metadata[0].name
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = var.traefik_chart_version

  atomic  = true
  timeout = 600

  values = [yamlencode({
    deployment = {
      replicas = local.replicas
    }
    podDisruptionBudget = {
      enabled      = var.high_availability
      minAvailable = 1
    }
    ingressClass = {
      enabled        = true
      isDefaultClass = true
    }
    providers = {
      kubernetesCRD = {
        enabled             = true
        allowCrossNamespace = false
      }
      kubernetesIngress = {
        enabled = true
        # Publishes the load balancer address on Ingress resources, which is
        # where ExternalDNS reads it.
        publishedService = {
          enabled = true
        }
      }
      kubernetesGateway = {
        enabled = var.enable_gateway_api
      }
    }
    ports = {
      web = {
        http = {
          redirections = {
            entryPoint = {
              to        = "websecure"
              scheme    = "https"
              permanent = true
            }
          }
        }
      }
    }
    service = {
      annotations = var.ingress_service_annotations
    }
    # The dashboard exposes the routing configuration; it stays off.
    ingressRoute = {
      dashboard = {
        enabled = false
      }
    }
    accessLog = {
      enabled = true
    }
    resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        memory = "512Mi"
      }
    }
  })]
}

# -----------------------------------------------------------------------------
# cert-manager
# -----------------------------------------------------------------------------

resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name       = "cert-manager"
  namespace  = kubernetes_namespace_v1.this["cert-manager"].metadata[0].name
  repository = "oci://quay.io/jetstack/charts"
  chart      = "cert-manager"
  version    = var.cert_manager_chart_version

  atomic  = true
  timeout = 600

  values = [yamlencode({
    crds = {
      enabled = true
      # Removing the release must not delete every Certificate in the cluster.
      keep = true
    }
    replicaCount = local.replicas
    podDisruptionBudget = {
      enabled = var.high_availability
    }
    global = {
      leaderElection = {
        namespace = "cert-manager"
      }
    }
    config = {
      apiVersion       = "controller.config.cert-manager.io/v1alpha1"
      kind             = "ControllerConfiguration"
      enableGatewayAPI = var.enable_gateway_api
    }
    webhook = {
      replicaCount = local.replicas
    }
  })]
}

# The ClusterIssuers are cert-manager resources, so they can only be created
# once its CRDs exist. A small local chart keeps that ordering inside Helm.
resource "helm_release" "cluster_issuers" {
  count = var.enable_cert_manager ? 1 : 0

  name      = "cluster-issuers"
  namespace = kubernetes_namespace_v1.this["cert-manager"].metadata[0].name
  chart     = "${path.module}/charts/cluster-issuers"

  atomic = true

  values = [yamlencode({
    email            = var.acme_email
    ingressClassName = var.ingress_class_name
  })]

  depends_on = [helm_release.cert_manager]
}

# -----------------------------------------------------------------------------
# ExternalDNS
# -----------------------------------------------------------------------------

resource "kubernetes_secret_v1" "dns_credentials" {
  count = local.dns_uses_token ? 1 : 0

  metadata {
    name      = local.dns_secret_name
    namespace = kubernetes_namespace_v1.this["external-dns"].metadata[0].name
  }

  # Write-only: the token reaches the cluster but is stored neither in the
  # plan nor in the state.
  data_wo = {
    api-token = var.dns_api_token
  }
  data_wo_revision = var.dns_api_token_revision

  lifecycle {
    precondition {
      condition     = var.dns_api_token != null && var.dns_api_token != ""
      error_message = "The ${var.dns_provider} provider needs an API token: set TF_VAR_dns_api_token (repository secret DNS_API_TOKEN)."
    }
  }
}

resource "helm_release" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name       = "external-dns"
  namespace  = kubernetes_namespace_v1.this["external-dns"].metadata[0].name
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = var.external_dns_chart_version

  atomic  = true
  timeout = 600

  values = [yamlencode({
    provider = {
      name = var.dns_provider
    }
    domainFilters = var.dns_domain_filters
    policy        = var.dns_policy
    # TXT records mark the records this installation owns, so it never
    # touches records created by anything else.
    registry   = "txt"
    txtOwnerId = var.name
    sources    = concat(["service", "ingress"], var.enable_gateway_api ? ["gateway-httproute"] : [])
    env = local.dns_uses_token ? [
      {
        name = local.dns_token_variable
        valueFrom = {
          secretKeyRef = {
            name = local.dns_secret_name
            key  = "api-token"
          }
        }
      },
    ] : []
    serviceAccount = {
      annotations = var.dns_service_account_annotations
    }
    resources = {
      requests = {
        cpu    = "50m"
        memory = "64Mi"
      }
      limits = {
        memory = "128Mi"
      }
    }
  })]

  depends_on = [kubernetes_secret_v1.dns_credentials]
}

# -----------------------------------------------------------------------------
# Metrics Server
# -----------------------------------------------------------------------------

resource "helm_release" "metrics_server" {
  count = var.enable_metrics_server ? 1 : 0

  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_chart_version

  atomic  = true
  timeout = 300

  values = [yamlencode({
    replicas = local.replicas
    podDisruptionBudget = {
      enabled      = var.high_availability
      minAvailable = 1
    }
    args = var.metrics_server_kubelet_insecure_tls ? ["--kubelet-insecure-tls"] : []
  })]
}
