# =============================================================================
# AWS VPC - Root Module
# =============================================================================
# This is the root module that calls the VPC child module.
# Environment-specific values are loaded from environments/*.tfvars files.
#
# Usage:
#   terraform init
#   terraform plan -var-file=environments/dev.tfvars
#   terraform apply -var-file=environments/dev.tfvars
# =============================================================================

module "vpc" {
  source = "./modules/vpc"

  # Required variables
  name        = var.name
  vpc_cidr    = var.vpc_cidr
  environment = var.environment

  # Optional variables - networking
  availability_zones_count = var.availability_zones_count
  enable_dns_hostnames     = var.enable_dns_hostnames
  enable_dns_support       = var.enable_dns_support

  # Optional variables - NAT Gateway
  enable_nat_gateway = var.enable_nat_gateway

  # Optional variables - Flow Logs
  enable_flow_logs         = var.enable_flow_logs
  flow_logs_traffic_type   = var.flow_logs_traffic_type
  flow_logs_retention_days = var.flow_logs_retention_days

  # Tags
  tags = var.tags
}
