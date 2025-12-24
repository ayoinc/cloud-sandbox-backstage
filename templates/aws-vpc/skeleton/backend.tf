# =============================================================================
# Terraform Backend Configuration
# =============================================================================
# S3 backend for remote state storage with DynamoDB for state locking.
# Backend configuration values are provided via -backend-config flags in CI/CD.
#
# Example:
#   terraform init \
#     -backend-config="bucket=my-terraform-state" \
#     -backend-config="key=my-project/vpc/dev/terraform.tfstate" \
#     -backend-config="region=us-east-1" \
#     -backend-config="encrypt=true" \
#     -backend-config="dynamodb_table=terraform-locks"
# =============================================================================

terraform {
  backend "s3" {
    # Values provided via -backend-config in CI/CD pipeline
    # bucket         = "provided-via-backend-config"
    # key            = "provided-via-backend-config"
    # region         = "provided-via-backend-config"
    # encrypt        = true
    # dynamodb_table = "provided-via-backend-config"
  }
}
