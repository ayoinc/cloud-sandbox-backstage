# =============================================================================
# AWS Provider Configuration
# =============================================================================
# Configures the AWS provider with default tags applied to all resources.
# =============================================================================

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "${{ values.owner }}"
    }
  }
}
