# =============================================================================
# Terraform and Provider Configuration
# =============================================================================
# This file contains the Terraform version constraints and AWS provider setup.
# =============================================================================

# -----------------------------------------------------------------------------
# AWS Provider
# -----------------------------------------------------------------------------
# Region is configured via AWS_REGION environment variable or can be
# passed as a variable. OIDC authentication is used in CI/CD pipelines.
# -----------------------------------------------------------------------------
provider "aws" {
  region = "${{ values.aws_region }}"

  default_tags {
    tags = {
      Project     = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "${{ values.owner }}"
      Repository  = "${{ values.destination.owner }}/${{ values.destination.repo }}"
    }
  }
}
