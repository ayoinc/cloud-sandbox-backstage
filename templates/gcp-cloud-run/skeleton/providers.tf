# =============================================================================
# GCP Cloud Run - Provider Configuration
# =============================================================================

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
