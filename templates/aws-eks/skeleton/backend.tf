# =============================================================================
# Terraform Backend Configuration
# =============================================================================
# S3 backend for remote state storage with DynamoDB locking.
# Actual values are passed via -backend-config in CI/CD pipeline.
#
# Example:
#   terraform init \
#     -backend-config="bucket=my-tf-state-bucket" \
#     -backend-config="key=eks/my-cluster/terraform.tfstate" \
#     -backend-config="region=us-east-1" \
#     -backend-config="encrypt=true" \
#     -backend-config="dynamodb_table=tf-state-lock"
# =============================================================================

terraform {
  backend "s3" {
    # Values provided via -backend-config flags
    # bucket         = "..."
    # key            = "..."
    # region         = "..."
    # encrypt        = true
    # dynamodb_table = "..."
  }
}
