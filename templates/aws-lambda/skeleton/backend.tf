# =============================================================================
# Terraform Backend Configuration
# =============================================================================
# Backend configuration for storing Terraform state remotely.
# Actual values are passed via -backend-config in CI/CD.
# =============================================================================

terraform {
  backend "s3" {
    # These values are provided via -backend-config flags:
    # -backend-config="bucket=<state-bucket>"
    # -backend-config="key=<org>/<project>/<env>/terraform.tfstate"
    # -backend-config="region=<region>"
    # -backend-config="encrypt=true"
    # -backend-config="dynamodb_table=<lock-table>" (optional)
  }
}
