# =============================================================================
# Kubernetes Platform Add-ons - Outputs
# =============================================================================

output "installed_add_ons" {
  description = "Chart version of every installed add-on."
  value = merge(
    { for release in helm_release.traefik : release.name => release.version },
    { for release in helm_release.cert_manager : release.name => release.version },
    { for release in helm_release.external_dns : release.name => release.version },
    { for release in helm_release.metrics_server : release.name => release.version },
  )
}

output "ingress_class_name" {
  description = "IngressClass to use in Ingress resources. Null when the ingress controller is not installed."
  value       = var.enable_ingress ? "traefik" : null
}

output "cluster_issuers" {
  description = "ClusterIssuers to reference in the cert-manager.io/cluster-issuer annotation."
  value       = var.enable_cert_manager ? ["letsencrypt-staging", "letsencrypt-production"] : []
}

output "namespaces" {
  description = "Namespaces created for the add-ons."
  value       = [for namespace in kubernetes_namespace_v1.this : namespace.metadata[0].name]
}
