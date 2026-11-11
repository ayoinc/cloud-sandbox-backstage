terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.0.0, < 9.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.35.0, < 3.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0, < 3.0.0"
    }
  }

  # The bucket is supplied at init time: terraform init -backend-config="bucket=<state bucket>"
  backend "gcs" {
    prefix = "${{ values.projectName }}/${{ values.environment }}/kubernetes-platform"
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.region

  default_labels = local.common_labels
}

# Short-lived access token of the identity Terraform runs as.
data "google_client_config" "current" {}

# Both providers talk to the cluster of this stack through its DNS-based endpoint. Google Cloud checks the token
# against IAM (permission container.clusters.connect) before a request reaches the Kubernetes API, and the endpoint
# presents a publicly trusted certificate, so no cluster CA certificate is configured.
provider "kubernetes" {
  host  = local.cluster_host
  token = data.google_client_config.current.access_token
}

provider "helm" {
  kubernetes {
    host  = local.cluster_host
    token = data.google_client_config.current.access_token
  }
}
