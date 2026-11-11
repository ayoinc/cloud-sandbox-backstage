# =============================================================================
# Oracle Cloud Compute - Provider Configuration
# =============================================================================
# Authentication uses the API signing key of the DEFAULT profile in
# ~/.oci/config. The pipeline writes that file from repository secrets at run
# time; no key is stored in this repository.
# =============================================================================

provider "oci" {
  region = var.region
}
