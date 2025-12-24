# =============================================================================
# GCP VPC - Provider Configuration
# =============================================================================
# Configures the Google Cloud provider with project and region.
# Uses Workload Identity Federation for authentication in CI/CD.
# =============================================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# Google Provider
# =============================================================================
provider "google" {
  project = "${{ values.gcpProject }}"
  region  = "${{ values.region }}"
}

# =============================================================================
# Google Beta Provider
# =============================================================================
provider "google-beta" {
  project = "${{ values.gcpProject }}"
  region  = "${{ values.region }}"
}
