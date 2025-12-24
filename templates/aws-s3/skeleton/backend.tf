# =============================================================================
# Terraform Backend Configuration
# =============================================================================
# S3 backend for state management. Values are provided via -backend-config
# flags in the CI/CD pipeline.
# =============================================================================

terraform {
  backend "s3" {
    # Backend configuration is provided via -backend-config flags
    # Example:
    # terraform init \
    #   -backend-config="bucket=my-terraform-state" \
    #   -backend-config="key=my-project/s3/dev/terraform.tfstate" \
    #   -backend-config="region=us-east-1" \
    #   -backend-config="encrypt=true" \
    #   -backend-config="dynamodb_table=terraform-locks"
  }
}
