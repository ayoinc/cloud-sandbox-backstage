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
private_subnet_ids = ["${{ values.privateSubnetIds | join('", "') }}"]

# Cluster Configuration
kubernetes_version      = "${{ values.kubernetesVersion }}"
endpoint_private_access = true
endpoint_public_access  = false
# To reach the API server from outside the VPC, enable the public endpoint for
# known networks only:
# endpoint_public_access = true
# public_access_cidrs    = ["203.0.113.0/24"]

# Node Group - Cost Optimized for Dev
node_instance_types = ["${{ values.nodeInstanceType }}"]
node_capacity_type  = "SPOT"
node_desired_size   = ${{ values.nodeDesiredSize }}
node_min_size       = 1
node_max_size       = ${{ values.nodeMaxSize }}
node_disk_size      = 30

# IRSA Roles
enable_cluster_autoscaler_irsa           = true
enable_aws_load_balancer_controller_irsa = true

# Tags
tags = {
  Environment = "dev"
  CostCenter  = "development"
}
