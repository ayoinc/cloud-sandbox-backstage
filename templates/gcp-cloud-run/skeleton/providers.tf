# =============================================================================
# GCP Cloud Run - Provider Configuration
# =============================================================================
# Configures the Google Cloud provider with Jinja2 template variables
# that will be substituted by Backstage when the template is scaffolded.
# =============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Google Cloud Provider
# -----------------------------------------------------------------------------
provider "google" {
  project = "${{ values.gcpProject }}"
  region  = "${{ values.region }}"

  # Default labels applied to all resources
  default_labels = {
    managed-by = "terraform"
    project    = "${{ values.name }}"
  }
}
