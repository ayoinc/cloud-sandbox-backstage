# =============================================================================
# Kubernetes Platform Add-ons - Backend Configuration
# =============================================================================
# Terraform state lives in a Secret in the cluster the add-ons are installed
# on, locked with a Lease, so no other storage is needed. The cluster is found
# through KUBE_CONFIG_PATH; the rest is supplied when initialising:
#
#   export KUBE_CONFIG_PATH=~/.kube/config
#   terraform init \
#     -backend-config="secret_suffix=<name>" \
#     -backend-config="namespace=kube-system"
# =============================================================================

terraform {
  backend "kubernetes" {}
}
