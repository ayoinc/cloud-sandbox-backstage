# =============================================================================
# AWS Provider Configuration
# =============================================================================
# Provider configuration with default tags.
# Region is set via environment variable or tfvars.
# =============================================================================

provider "aws" {
  region = "${{ values.aws_region }}"

  default_tags {
    tags = {
      Project      = "${{ values.name }}"
      ManagedBy    = "terraform"
      Repository   = "${{ values.destination.owner }}/${{ values.destination.repo }}"
      Environment  = var.environment
      TemplateType = "aws-lambda"
    }
  }
}

provider "archive" {
  # Archive provider for zipping Lambda code
}
