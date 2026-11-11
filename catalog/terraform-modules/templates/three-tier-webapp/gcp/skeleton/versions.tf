terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.0.0, < 9.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0, < 4.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0, < 5.0.0"
    }
  }

  # The bucket is supplied at init time: terraform init -backend-config="bucket=<state bucket>"
  backend "gcs" {
    prefix = "${{ values.projectName }}/${{ values.environment }}/three-tier"
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.region

  default_labels = local.common_labels
}
