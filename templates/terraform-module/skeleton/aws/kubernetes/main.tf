# -----------------------------------------------------------------------------
# AWS Kubernetes (EKS) Module - Main Resources
# -----------------------------------------------------------------------------

data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  # Lowercase, hyphen-separated and short enough for every AWS name limit.
  project     = trimsuffix(substr(replace(lower(var.project_name), "/[^a-z0-9]+/", "-"), 0, 23), "-")
  name_prefix = "${local.project}-${var.environment}"

  cluster_name          = local.name_prefix
  managed_policy_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"

  secrets_kms_key_arn = var.create_kms_key ? aws_kms_key.secrets[0].arn : var.kms_key_arn

  oidc_issuer      = aws_eks_cluster.main.identity[0].oidc[0].issuer
  oidc_issuer_host = trimprefix(local.oidc_issuer, "https://")
}

# -----------------------------------------------------------------------------
# Secrets encryption key
# -----------------------------------------------------------------------------

resource "aws_kms_key" "secrets" {
  count = var.create_kms_key ? 1 : 0

  description             = "Envelope encryption of Kubernetes secrets in ${local.cluster_name}"
  deletion_window_in_days = var.environment == "prod" ? 30 : 7
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-eks-secrets"
  })
}

resource "aws_kms_alias" "secrets" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${local.name_prefix}-eks-secrets"
  target_key_id = aws_kms_key.secrets[0].key_id
}

# -----------------------------------------------------------------------------
# Cluster
# -----------------------------------------------------------------------------

resource "aws_iam_role" "cluster" {
  name = "${local.name_prefix}-eks-cluster-role"

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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "${local.managed_policy_prefix}/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_controller" {
  policy_arn = "${local.managed_policy_prefix}/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# Additional security group on the control plane network interfaces. It
# carries the rules that let private networks reach the API endpoint.
resource "aws_security_group" "cluster" {
  name_prefix = "${local.name_prefix}-eks-cluster-"
  description = "EKS control plane access for ${local.cluster_name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-eks-cluster-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "cluster_api" {
  count = length(var.private_access_cidrs)

  security_group_id = aws_security_group.cluster.id
  description       = "Kubernetes API from an allowed private network"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.private_access_cidrs[count.index]

  tags = var.tags
}

# EKS writes control plane logs to this group; creating it first sets
# retention and encryption.
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true

    # The public endpoint is off by default; turning it on is an explicit
    # choice for operators without private connectivity to the VPC.
    # trivy:ignore:AVD-AWS-0040
    endpoint_public_access = var.enable_public_access

    # Public access is limited to an allow-list that variable validation
    # keeps non-empty and free of 0.0.0.0/0.
    # trivy:ignore:AVD-AWS-0041
    public_access_cidrs = var.enable_public_access ? var.public_access_cidrs : null
  }

  enabled_cluster_log_types = var.enabled_log_types

  encryption_config {
    provider {
      key_arn = local.secrets_kms_key_arn
    }
    resources = ["secrets"]
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.create_kms_key || var.kms_key_arn != null
      error_message = "kms_key_arn must be set when create_kms_key is false: Kubernetes secrets are always envelope encrypted."
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_controller,
    aws_cloudwatch_log_group.eks,
  ]
}

# -----------------------------------------------------------------------------
# OIDC provider for IAM roles for service accounts
# -----------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list = ["sts.amazonaws.com"]
  url            = local.oidc_issuer

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Managed node group
# -----------------------------------------------------------------------------

resource "aws_iam_role" "node" {
  name = "${local.name_prefix}-eks-node-role"

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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  policy_arn = "${local.managed_policy_prefix}/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  policy_arn = "${local.managed_policy_prefix}/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  policy_arn = "${local.managed_policy_prefix}/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_ssm_policy" {
  policy_arn = "${local.managed_policy_prefix}/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

# Node settings EKS merges into the launch template it generates: encrypted
# root volume and IMDSv2 only. The hop limit of 2 lets pods on the pod network
# reach the metadata service, as with the EKS default template.
resource "aws_launch_template" "node" {
  name_prefix = "${local.name_prefix}-eks-node-"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${local.name_prefix}-eks-node"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name = "${local.name_prefix}-eks-node"
    })
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.name_prefix}-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  ami_type       = var.node_ami_type
  instance_types = var.node_instance_types
  capacity_type  = var.capacity_type

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  scaling_config {
    min_size     = var.node_min_size
    max_size     = var.node_max_size
    desired_size = var.node_desired_size
  }

  update_config {
    max_unavailable_percentage = 25
  }

  labels = merge(var.node_labels, {
    environment = var.environment
  })

  dynamic "taint" {
    for_each = var.node_taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# -----------------------------------------------------------------------------
# Addons
# -----------------------------------------------------------------------------

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

# CoreDNS and the EBS CSI controller run as pods, so they need nodes.
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [aws_eks_node_group.main]
}

resource "aws_iam_role" "ebs_csi" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  name = "${local.name_prefix}-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Condition = {
        StringEquals = {
          "${local.oidc_issuer_host}:aud" = "sts.amazonaws.com"
          "${local.oidc_issuer_host}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  policy_arn = "${local.managed_policy_prefix}/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi[0].name
}

resource "aws_eks_addon" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"

  service_account_role_arn = aws_iam_role.ebs_csi[0].arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi,
  ]
}
