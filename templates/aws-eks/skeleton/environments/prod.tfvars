# =============================================================================
# Production Environment - EKS Configuration
# =============================================================================
# High-availability, secure configuration for production workloads.
# Uses ON_DEMAND instances with private endpoint only.
#
# Usage: terraform plan -var-file=environments/prod.tfvars
# =============================================================================

# Project Configuration (from Backstage scaffolder)
name        = "${{ values.name }}"
environment = "prod"

# VPC Configuration (assumes VPC already exists)
vpc_id             = "${{ values.vpcId }}"
private_subnet_ids = ${{ values.privateSubnetIds | default('["subnet-placeholder-1", "subnet-placeholder-2", "subnet-placeholder-3"]') }}

# Cluster Configuration
kubernetes_version      = "${{ values.kubernetesVersion | default('1.31') }}"
endpoint_private_access = true
endpoint_public_access  = false  # Private only for production security

# Node Group - Production Configuration
node_instance_types = ["m5.large", "m5a.large", "m6i.large"]
node_capacity_type  = "ON_DEMAND"  # Always ON_DEMAND for production
node_desired_size   = 3
node_min_size       = 3            # Higher minimum for HA
node_max_size       = 10
node_disk_size      = 100

# IRSA Roles
enable_cluster_autoscaler_irsa           = true
enable_aws_load_balancer_controller_irsa = true

# Tags
tags = {
  Environment  = "prod"
  CostCenter   = "production"
  Compliance   = "required"
  BackupPolicy = "daily"
}
