# =============================================================================
# Oracle Cloud Compute - Backend Configuration
# =============================================================================
# Terraform state lives in an OCI Object Storage bucket, which also locks it.
# Credentials come from the DEFAULT profile of ~/.oci/config; the rest is
# supplied when initialising:
#
#   terraform init \
#     -backend-config="bucket=<state bucket>" \
#     -backend-config="namespace=<object storage namespace>" \
#     -backend-config="region=<region>" \
#     -backend-config="key=<project>/<environment>/terraform.tfstate"
# =============================================================================

terraform {
  backend "oci" {}
}
