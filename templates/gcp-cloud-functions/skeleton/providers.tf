# =============================================================================
# GCP Cloud Run Functions - Provider Configuration
# =============================================================================
# Authentication comes from the environment: Workload Identity Federation in
# the pipeline, or `gcloud auth application-default login` locally.
# =============================================================================

provider "google" {
  project = var.project_id
  region  = var.region
}
