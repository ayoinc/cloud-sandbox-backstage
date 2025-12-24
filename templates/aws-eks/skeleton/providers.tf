# =============================================================================
# Provider Configuration
# =============================================================================
# AWS and Kubernetes provider configuration with default tags.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "${{ values.region | default('us-east-1') }}"

  default_tags {
    tags = {
      Project     = "${{ values.name }}"
      Owner       = "${{ values.owner }}"
      ManagedBy   = "terraform"
      Repository  = "${{ values.repoUrl | default('') }}"
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
