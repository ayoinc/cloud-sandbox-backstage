# =============================================================================
# GCP VPC - Provider Configuration
# =============================================================================
# Configures the Google Cloud provider with project and region.
# Uses Workload Identity Federation for authentication in CI/CD.
# =============================================================================

# =============================================================================
# Google Provider
# =============================================================================
provider "google" {
  project = "${{ values.gcpProject }}"
  region  = "${{ values.region }}"
}
