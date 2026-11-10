# =============================================================================
# Provider Configuration
# =============================================================================
# AWS and Kubernetes provider configuration with default tags.
# =============================================================================

provider "aws" {
  region = "${{ values.region }}"

  default_tags {
    tags = {
      Project    = "${{ values.name }}"
      Owner      = "${{ values.owner }}"
      ManagedBy  = "terraform"
      Repository = "${{ values.destination.owner }}/${{ values.destination.repo }}"
    }
  }
}

# Kubernetes provider configured after cluster creation
# This is used for deploying Kubernetes resources post-cluster creation
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}
