# -----------------------------------------------------------------------------
# EKS cluster
# -----------------------------------------------------------------------------
resource "aws_iam_role" "eks_cluster" {
  count = var.enable_containers ? 1 : 0

  name = "${local.name}-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  count = var.enable_containers ? 1 : 0

  role       = aws_iam_role.eks_cluster[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_security_group" "eks_cluster" {
  count = var.enable_containers ? 1 : 0

  name        = "${local.name}-eks-cluster"
  description = "Control plane of the ${local.name} EKS cluster"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${local.name}-eks-cluster"
  }
}

resource "aws_vpc_security_group_egress_rule" "eks_cluster_vpc" {
  count = var.enable_containers ? 1 : 0

  security_group_id = aws_security_group.eks_cluster[0].id
  description       = "Control plane to nodes and pods inside the VPC"
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_eks_cluster" "main" {
  count = var.enable_containers ? 1 : 0

  name     = local.name
  version  = var.eks_version
  role_arn = aws_iam_role.eks_cluster[0].arn

  vpc_config {
    subnet_ids              = local.private_subnet_ids
    security_group_ids      = [aws_security_group.eks_cluster[0].id]
    endpoint_private_access = true
    endpoint_public_access  = var.eks_endpoint_public_access
    public_access_cidrs     = var.eks_endpoint_public_access ? var.eks_public_access_cidrs : null
  }

  encryption_config {
    resources = ["secrets"]

    provider {
      key_arn = aws_kms_key.main.arn
    }
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  lifecycle {
    precondition {
      condition     = !var.eks_endpoint_public_access || length(var.eks_public_access_cidrs) > 0
      error_message = "Set eks_public_access_cidrs to the networks that may reach the API server when eks_endpoint_public_access is true."
    }
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}

# Lets Kubernetes service accounts assume IAM roles (IRSA).
resource "aws_iam_openid_connect_provider" "eks" {
  count = var.enable_containers ? 1 : 0

  url            = aws_eks_cluster.main[0].identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
}

# -----------------------------------------------------------------------------
# Managed node group
# -----------------------------------------------------------------------------
resource "aws_iam_role" "eks_nodes" {
  count = var.enable_containers ? 1 : 0

  name = "${local.name}-eks-nodes"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_nodes" {
  for_each = var.enable_containers ? toset([
    "AmazonEKSWorkerNodePolicy",
    "AmazonEKS_CNI_Policy",
    "AmazonEC2ContainerRegistryReadOnly",
    "AmazonSSMManagedInstanceCore",
  ]) : toset([])

  role       = aws_iam_role.eks_nodes[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/${each.value}"
}

resource "aws_eks_node_group" "main" {
  count = var.enable_containers ? 1 : 0

  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = "${local.name}-nodes"
  node_role_arn   = aws_iam_role.eks_nodes[0].arn
  subnet_ids      = local.private_subnet_ids
  instance_types  = var.eks_node_group_instance_types

  scaling_config {
    desired_size = var.eks_desired_nodes
    min_size     = var.eks_min_nodes
    max_size     = var.eks_max_nodes
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_nodes]
}

# -----------------------------------------------------------------------------
# Container registry
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "main" {
  count = var.enable_containers ? 1 : 0

  name                 = local.name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.main.arn
  }
}

resource "aws_ecr_lifecycle_policy" "main" {
  count = var.enable_containers ? 1 : 0

  repository = aws_ecr_repository.main[0].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the 50 most recent images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 50
      }
      action = { type = "expire" }
    }]
  })
}
