# =============================================================================
# Development Environment - EKS Configuration
# =============================================================================
# Cost-optimized configuration for development workloads.
# Uses SPOT instances and smaller node counts.
#
# Usage: terraform plan -var-file=environments/dev.tfvars
# =============================================================================

# Project Configuration (from Backstage scaffolder)
name        = "${{ values.name }}"
environment = "dev"

# VPC Configuration (assumes VPC already exists)
# These will be looked up by data sources
vpc_id             = "${{ values.vpcId }}"
private_subnet_ids = ${{ values.privateSubnetIds | default('["subnet-placeholder-1", "subnet-placeholder-2"]') }}

# Cluster Configuration
kubernetes_version      = "${{ values.kubernetesVersion | default('1.31') }}"
endpoint_private_access = true
endpoint_public_access  = true  # Allow public access for dev

# Node Group - Cost Optimized for Dev
node_instance_types = ["t3.medium", "t3a.medium"]
node_capacity_type  = "SPOT"  # Use SPOT for cost savings in dev
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 4
node_disk_size      = 30

# IRSA Roles
enable_cluster_autoscaler_irsa           = true
enable_aws_load_balancer_controller_irsa = true

# Tags
tags = {
  Environment = "dev"
  CostCenter  = "development"
}
