# =============================================================================
# AWS Provider Configuration
# =============================================================================
# Provider configuration with default tags.
# Region is set via environment variable or tfvars.
# =============================================================================

provider "aws" {
  region = "${{ values.region | default('us-east-1') }}"

  default_tags {
    tags = {
      Project       = "${{ values.name }}"
      ManagedBy     = "terraform"
      Repository    = "${{ values.repoUrl | default('') }}"
      Environment   = var.environment
      TemplateType  = "aws-lambda"
    }
  }
}

provider "archive" {
  # Archive provider for zipping Lambda code
}
