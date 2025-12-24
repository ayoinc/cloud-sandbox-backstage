# =============================================================================
# Terraform Backend Configuration
# =============================================================================
# S3 backend for state management. Values are provided via -backend-config
# flags in the CI/CD pipeline.
#
# Required backend configuration (provided via CLI):
#   -backend-config="bucket=<state-bucket>"
#   -backend-config="key=<project>/terraform.tfstate"
#   -backend-config="region=<aws-region>"
#   -backend-config="encrypt=true"
#   -backend-config="dynamodb_table=<lock-table>" (optional)
# =============================================================================

terraform {
  backend "s3" {
    # Backend configuration is provided via -backend-config flags
    # This allows different state files per environment
    #
    # Example:
    # terraform init \
    #   -backend-config="bucket=my-terraform-state" \
    #   -backend-config="key=my-project/rds/dev/terraform.tfstate" \
    #   -backend-config="region=us-east-1" \
    #   -backend-config="encrypt=true" \
    #   -backend-config="dynamodb_table=terraform-locks"
  }
}
