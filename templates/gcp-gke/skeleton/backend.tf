# =============================================================================
# GCP GKE - Backend Configuration
# =============================================================================
# Terraform state is stored in Google Cloud Storage (GCS).
# Backend configuration is provided via CLI flags in CI/CD.
# =============================================================================

terraform {
  backend "gcs" {
    # Backend configuration provided via CLI:
    # terraform init \
    #   -backend-config="bucket=<GCS_BUCKET>" \
    #   -backend-config="prefix=<PROJECT>/<ENVIRONMENT>"
    #
    # Example:
    # terraform init \
    #   -backend-config="bucket=my-terraform-state" \
    #   -backend-config="prefix=my-gke-cluster/dev"
  }
}
