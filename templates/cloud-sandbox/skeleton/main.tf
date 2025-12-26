# =============================================================================
# Cloud Sandbox Infrastructure
# =============================================================================
# Root module that calls the sandbox child module.
# This provides a quick way to spin up a complete cloud environment.
# =============================================================================

# -----------------------------------------------------------------------------
# Sandbox Module
# -----------------------------------------------------------------------------
module "sandbox" {
  source = "./modules/sandbox"

  # Project Configuration
  name        = var.name
  environment = var.environment
  region      = var.region

  # Network Configuration
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  # Optional Components
  include_bastion = var.include_bastion
  include_eks     = var.include_eks
  include_rds     = var.include_rds

  # Tags
  tags = var.tags
}
