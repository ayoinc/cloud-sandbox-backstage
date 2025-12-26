# =============================================================================
# Cloud Sandbox Provider Configuration
# =============================================================================

provider "aws" {
  region = var.region

  default_tags {
    tags = merge(var.tags, {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.name
    })
  }
}
