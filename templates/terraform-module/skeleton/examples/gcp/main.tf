# ==============================================================================
# GCP Example - Complete Deployment
# ==============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Use the root module
module "infrastructure" {
  source = "../../"

  environment      = var.environment
  project_name     = var.project_name
  gcp_project_id   = var.gcp_project_id
  gcp_region       = var.gcp_region
  gcp_zone         = var.gcp_zone
  gcp_network_cidr = var.gcp_network_cidr

  # Enable desired modules
  enable_compute       = true
  enable_network       = true
  enable_storage       = true
  enable_database      = false
  enable_security      = true
  enable_observability = true
  enable_kubernetes    = false
  enable_serverless    = false

  tags = var.tags
}
