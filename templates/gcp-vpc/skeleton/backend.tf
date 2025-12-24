# =============================================================================
# GCP VPC - Backend Configuration
# =============================================================================
# Uses Google Cloud Storage (GCS) for remote state storage.
# Backend configuration is passed via CLI flags in the workflow.
# =============================================================================

terraform {
  backend "gcs" {
    # Configuration provided via -backend-config flags:
    # -backend-config="bucket=<bucket-name>"
    # -backend-config="prefix=<project>/<environment>"
  }
}
