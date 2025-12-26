# ==============================================================================
# AWS Example - Complete Deployment
# ==============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Example     = "true"
    }
  }
}

# Use the root module
module "infrastructure" {
  source = "../../"

  environment            = var.environment
  project_name           = var.project_name
  aws_region             = var.aws_region
  aws_vpc_cidr           = var.aws_vpc_cidr
  aws_availability_zones = var.aws_availability_zones

  # Enable desired modules
  enable_compute       = true
  enable_network       = true
  enable_storage       = true
  enable_database      = false
  enable_security      = true
  enable_observability = true
  enable_kubernetes    = false
  enable_serverless    = false

  tags = var.tags
}
