# =============================================================================
# AWS EKS Module
# =============================================================================
# Reusable module for creating an EKS cluster with managed node groups,
# IAM roles, and OIDC provider for IRSA.
# =============================================================================

locals {
  cluster_name = "${var.name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# IAM Role for EKS Cluster
# -----------------------------------------------------------------------------
resource "aws_iam_role" "cluster" {
  name = "${local.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${local.cluster_name}-cluster-role"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# -----------------------------------------------------------------------------
# IAM Role for Node Group
# -----------------------------------------------------------------------------
resource "aws_iam_role" "node_group" {
  name = "${local.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${local.cluster_name}-node-role"
  })
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ])

  policy_arn = each.value
  role       = aws_iam_role.node_group.name
}

# -----------------------------------------------------------------------------
# Security Group for Cluster
# -----------------------------------------------------------------------------
resource "aws_security_group" "cluster" {
  name        = "${local.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, {
    Name                                          = "${local.cluster_name}-cluster-sg"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  })
}

# -----------------------------------------------------------------------------
# EKS Cluster
# -----------------------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : null
    security_group_ids      = [aws_security_group.cluster.id]
  }

  enabled_cluster_log_types = var.cluster_enabled_log_types

  # Ensure IAM role policies are attached before creating cluster
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_resource_controller,
  ]

  tags = merge(var.tags, {
    Name = local.cluster_name
  })
}

# -----------------------------------------------------------------------------
# EKS Managed Node Group
# -----------------------------------------------------------------------------
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.node_instance_types
  capacity_type  = var.node_capacity_type
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = merge(
    {
      environment = var.environment
      managed-by  = "terraform"
    },
    var.node_labels
  )

  dynamic "taint" {
    for_each = var.node_taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  # Ensure IAM role policies are attached before creating node group
  depends_on = [
    aws_iam_role_policy_attachment.node_policies,
  ]

  tags = merge(var.tags, {
    Name = "${local.cluster_name}-nodes"
  })

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# -----------------------------------------------------------------------------
# OIDC Provider for IRSA (IAM Roles for Service Accounts)
# -----------------------------------------------------------------------------
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = merge(var.tags, {
    Name = "${local.cluster_name}-oidc"
  })
}

# -----------------------------------------------------------------------------
# IRSA Role for Cluster Autoscaler (Optional)
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "cluster_autoscaler_assume_role" {
  count = var.enable_cluster_autoscaler_irsa ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler_irsa ? 1 : 0

  name               = "${local.cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_assume_role[0].json

  tags = merge(var.tags, {
    Name = "${local.cluster_name}-cluster-autoscaler"
  })
}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler_irsa ? 1 : 0

  name = "${local.cluster_name}-cluster-autoscaler"
  role = aws_iam_role.cluster_autoscaler[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeImages",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "autoscaling:ResourceTag/kubernetes.io/cluster/${local.cluster_name}" = "owned"
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# IRSA Role for AWS Load Balancer Controller (Optional)
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "aws_lb_controller_assume_role" {
  count = var.enable_aws_load_balancer_controller_irsa ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
    }
  }
}

resource "aws_iam_role" "aws_lb_controller" {
  count = var.enable_aws_load_balancer_controller_irsa ? 1 : 0

  name               = "${local.cluster_name}-aws-lb-controller"
  assume_role_policy = data.aws_iam_policy_document.aws_lb_controller_assume_role[0].json

  tags = merge(var.tags, {
    Name = "${local.cluster_name}-aws-lb-controller"
  })
}
