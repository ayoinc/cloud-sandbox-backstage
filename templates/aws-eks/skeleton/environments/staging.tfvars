# =============================================================================
# Staging Environment - EKS Configuration
# =============================================================================
# Production-like configuration for pre-production testing.
# Uses ON_DEMAND instances with moderate capacity.
#
# Usage: terraform plan -var-file=environments/staging.tfvars
# =============================================================================

# Project Configuration (from Backstage scaffolder)
name        = "${{ values.name }}"
environment = "staging"

# VPC Configuration (assumes VPC already exists)
vpc_id             = "${{ values.vpcId }}"
private_subnet_ids = ${{ values.privateSubnetIds | default('["subnet-placeholder-1", "subnet-placeholder-2"]') }}

# Cluster Configuration
kubernetes_version      = "${{ values.kubernetesVersion | default('1.31') }}"
endpoint_private_access = true
endpoint_public_access  = true  # Still allow public access for staging

# Node Group - Moderate Configuration
node_instance_types = ["t3.large", "t3a.large"]
node_capacity_type  = "ON_DEMAND"  # Use ON_DEMAND for stability
node_desired_size   = 3
node_min_size       = 2
node_max_size       = 6
node_disk_size      = 50

# IRSA Roles
enable_cluster_autoscaler_irsa           = true
enable_aws_load_balancer_controller_irsa = true

# Tags
tags = {
  Environment = "staging"
  CostCenter  = "pre-production"
}
