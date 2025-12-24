# =============================================================================
# AWS EKS - Root Module
# =============================================================================
# This is the root module that calls the EKS child module.
# Environment-specific values are loaded from environments/*.tfvars files.
#
# Usage:
#   terraform init
#   terraform plan -var-file=environments/dev.tfvars
#   terraform apply -var-file=environments/dev.tfvars
# =============================================================================

module "eks" {
  source = "./modules/eks"

  # Required variables
  name               = var.name
  environment        = var.environment
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids

  # Cluster Configuration
  kubernetes_version      = var.kubernetes_version
  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access

  # Node Group Configuration
  node_instance_types = var.node_instance_types
  node_capacity_type  = var.node_capacity_type
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_disk_size      = var.node_disk_size

  # IRSA Roles
  enable_cluster_autoscaler_irsa           = var.enable_cluster_autoscaler_irsa
  enable_aws_load_balancer_controller_irsa = var.enable_aws_load_balancer_controller_irsa

  # Tags
  tags = var.tags
}
