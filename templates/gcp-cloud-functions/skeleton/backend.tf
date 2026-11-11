# =============================================================================
# GCP Cloud Run Functions - Backend Configuration
# =============================================================================
# Terraform state is stored in Google Cloud Storage.
# Backend values are provided with -backend-config flags.
# =============================================================================

terraform {
  backend "gcs" {
    # terraform init \
    #   -backend-config="bucket=<state-bucket>" \
    #   -backend-config="prefix=<project>/<environment>"
  }
}
