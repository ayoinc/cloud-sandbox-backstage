terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.10.0, < 9.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 8.10.0, < 9.0.0"
    }
  }

  # The bucket is supplied at init time: terraform init -backend-config="bucket=<state bucket>"
  backend "gcs" {
    prefix = "${{ values.projectName }}/${{ values.environment }}/data-platform"
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.region

  default_labels = local.labels
}

# Only used for google_project_service_identity, which the stable provider does not offer.
provider "google-beta" {
  project = var.gcp_project_id
  region  = var.region
}
