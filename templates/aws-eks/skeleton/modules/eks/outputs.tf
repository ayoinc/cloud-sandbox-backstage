# =============================================================================
# AWS EKS Module - Outputs
# =============================================================================
# Output values from the EKS module for use by other modules or resources.
# =============================================================================

# -----------------------------------------------------------------------------
# Cluster Outputs
# -----------------------------------------------------------------------------
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "The Kubernetes version of the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_platform_version" {
  description = "The platform version of the EKS cluster"
  value       = aws_eks_cluster.this.platform_version
}

# -----------------------------------------------------------------------------
# Security Group Outputs
# -----------------------------------------------------------------------------
output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster control plane"
  value       = aws_security_group.cluster.id
}

output "cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by EKS"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

# -----------------------------------------------------------------------------
# IAM Role Outputs
# -----------------------------------------------------------------------------
output "cluster_iam_role_arn" {
  description = "ARN of the IAM role used by the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "Name of the IAM role used by the EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "node_group_iam_role_arn" {
  description = "ARN of the IAM role used by the EKS node group"
  value       = aws_iam_role.node_group.arn
}

output "node_group_iam_role_name" {
  description = "Name of the IAM role used by the EKS node group"
  value       = aws_iam_role.node_group.name
}

# -----------------------------------------------------------------------------
# OIDC Provider Outputs
# -----------------------------------------------------------------------------
output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.cluster.url
}

output "oidc_issuer" {
  description = "The OIDC issuer URL for the cluster"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# -----------------------------------------------------------------------------
# Node Group Outputs
# -----------------------------------------------------------------------------
output "node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.this.id
}

output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.this.arn
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = aws_eks_node_group.this.status
}

output "node_group_resources" {
  description = "List of resources associated with the node group"
  value       = aws_eks_node_group.this.resources
}

# -----------------------------------------------------------------------------
# IRSA Role Outputs
# -----------------------------------------------------------------------------
output "cluster_autoscaler_role_arn" {
  description = "ARN of the IAM role for Cluster Autoscaler"
  value       = var.enable_cluster_autoscaler_irsa ? aws_iam_role.cluster_autoscaler[0].arn : null
}

output "aws_lb_controller_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = var.enable_aws_load_balancer_controller_irsa ? aws_iam_role.aws_lb_controller[0].arn : null
}

# -----------------------------------------------------------------------------
# Utility Outputs
# -----------------------------------------------------------------------------
output "kubeconfig_command" {
  description = "AWS CLI command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region $(aws configure get region) --name ${aws_eks_cluster.this.name}"
}
