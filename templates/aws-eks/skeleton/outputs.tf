# =============================================================================
# AWS EKS - Root Outputs
# =============================================================================
# Outputs from the root module, exposing values from the EKS child module.
# =============================================================================

# -----------------------------------------------------------------------------
# Cluster Outputs
# -----------------------------------------------------------------------------
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes version of the cluster"
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Security Group Outputs
# -----------------------------------------------------------------------------
output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by EKS"
  value       = module.eks.cluster_primary_security_group_id
}

# -----------------------------------------------------------------------------
# IAM Role Outputs
# -----------------------------------------------------------------------------
output "cluster_iam_role_arn" {
  description = "ARN of the IAM role used by the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "node_group_iam_role_arn" {
  description = "ARN of the IAM role used by the EKS node group"
  value       = module.eks.node_group_iam_role_arn
}

# -----------------------------------------------------------------------------
# OIDC Provider Outputs
# -----------------------------------------------------------------------------
output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "oidc_issuer" {
  description = "The OIDC issuer URL for the cluster"
  value       = module.eks.oidc_issuer
}

# -----------------------------------------------------------------------------
# Node Group Outputs
# -----------------------------------------------------------------------------
output "node_group_id" {
  description = "EKS node group ID"
  value       = module.eks.node_group_id
}

output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = module.eks.node_group_arn
}

# -----------------------------------------------------------------------------
# IRSA Role Outputs
# -----------------------------------------------------------------------------
output "cluster_autoscaler_role_arn" {
  description = "ARN of the IAM role for Cluster Autoscaler"
  value       = module.eks.cluster_autoscaler_role_arn
}

output "aws_lb_controller_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = module.eks.aws_lb_controller_role_arn
}

# -----------------------------------------------------------------------------
# Utility Outputs
# -----------------------------------------------------------------------------
output "kubeconfig_command" {
  description = "AWS CLI command to update kubeconfig"
  value       = module.eks.kubeconfig_command
}
