# =============================================================================
# Kubernetes Platform Add-ons - Provider Configuration
# =============================================================================
# Both providers find the cluster through the KUBE_CONFIG_PATH environment
# variable. No kubeconfig or credential is stored in this repository.
# =============================================================================

provider "kubernetes" {
  config_context = var.kube_context
}

provider "helm" {
  kubernetes = {
    config_context = var.kube_context
  }
}
