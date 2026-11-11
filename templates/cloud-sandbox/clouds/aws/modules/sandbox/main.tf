data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = data.aws_availability_zones.available.names

  # EKS and RDS both need subnets in two availability zones.
  private_subnet_count = (var.include_eks || var.include_rds) ? max(var.private_subnets, 2) : var.private_subnets

  # The VPC CIDR is cut into 16 equal blocks: 0-3 public, 8-11 private.
  public_subnet_cidrs  = [for i in range(var.public_subnets) : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnet_cidrs = [for i in range(local.private_subnet_count) : cidrsubnet(var.vpc_cidr, 4, i + 8)]

  # Database names must start with a letter and cannot contain hyphens.
  database_name = "db_${replace(var.name, "-", "_")}"
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = var.name
  })
}

# The default security group allows nothing, so resources must use an explicit one.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-default"
  })
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/${var.name}/flow-logs"
  retention_in_days = 14

  tags = var.tags
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.name}-vpc-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "write-flow-logs"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
      ]
      Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
    }]
  })
}

resource "aws_flow_log" "this" {
  vpc_id          = aws_vpc.this.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_subnet" "public" {
  count = var.public_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.public_subnet_cidrs[count.index]
  availability_zone = element(local.azs, count.index)

  tags = merge(var.tags, {
    Name                     = "${var.name}-public-${count.index + 1}"
    Tier                     = "public"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-public"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = var.public_subnets

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private" {
  count = local.private_subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = element(local.azs, count.index)

  tags = merge(var.tags, {
    Name                              = "${var.name}-private-${count.index + 1}"
    Tier                              = "private"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# One NAT gateway serves all private subnets: cheaper than one per zone and
# enough for a sandbox.
resource "aws_eip" "nat" {
  count = local.private_subnet_count > 0 ? 1 : 0

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.private_subnet_count > 0 ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_route_table" "private" {
  count = local.private_subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-private"
  })
}

resource "aws_route" "private_nat" {
  count = local.private_subnet_count > 0 ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  count = local.private_subnet_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# -----------------------------------------------------------------------------
# Bastion host (optional)
# -----------------------------------------------------------------------------

data "aws_ami" "amazon_linux" {
  count = var.include_bastion ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_role" "bastion" {
  count = var.include_bastion ? 1 : 0

  name = "${var.name}-bastion"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = var.tags
}

# Session Manager access, so the bastion needs no SSH key and no open port.
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  count = var.include_bastion ? 1 : 0

  role       = aws_iam_role.bastion[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  count = var.include_bastion ? 1 : 0

  name = "${var.name}-bastion"
  role = aws_iam_role.bastion[0].name

  tags = var.tags
}

resource "aws_security_group" "bastion" {
  count = var.include_bastion ? 1 : 0

  name        = "${var.name}-bastion"
  description = "Bastion host of the ${var.name} sandbox"
  vpc_id      = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-bastion"
  })
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  for_each = var.include_bastion ? toset(var.bastion_allowed_cidrs) : []

  security_group_id = aws_security_group.bastion[0].id
  description       = "SSH from ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

# Session Manager and the package repositories are reached over HTTPS at
# addresses that change, so the destination cannot be narrowed to a CIDR list.
# trivy:ignore:AVD-AWS-0104
resource "aws_vpc_security_group_egress_rule" "bastion_https" {
  count = var.include_bastion ? 1 : 0

  security_group_id = aws_security_group.bastion[0].id
  description       = "HTTPS for Session Manager and package updates"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_instance" "bastion" {
  count = var.include_bastion ? 1 : 0

  ami                         = data.aws_ami.amazon_linux[0].id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion[0].id]
  iam_instance_profile        = aws_iam_instance_profile.bastion[0].name
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-bastion"
    Role = "bastion"
  })

  # A newer AMI must not replace a running bastion on the next apply.
  lifecycle {
    ignore_changes = [ami]
  }

  # Session Manager registration needs the route to the internet.
  depends_on = [aws_route.public_internet]
}

# -----------------------------------------------------------------------------
# EKS cluster (optional)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "eks_cluster" {
  count = var.include_eks ? 1 : 0

  name = "${var.name}-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  count = var.include_eks ? 1 : 0

  role       = aws_iam_role.eks_cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_kms_key" "eks" {
  count = var.include_eks ? 1 : 0

  description             = "Encrypts Kubernetes secrets of the ${var.name} EKS cluster"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = var.tags
}

resource "aws_eks_cluster" "this" {
  count = var.include_eks ? 1 : 0

  name     = var.name
  role_arn = aws_iam_role.eks_cluster[0].arn
  version  = var.kubernetes_version

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = length(var.eks_public_access_cidrs) > 0
    public_access_cidrs     = length(var.eks_public_access_cidrs) > 0 ? var.eks_public_access_cidrs : null
  }

  encryption_config {
    resources = ["secrets"]

    provider {
      key_arn = aws_kms_key.eks[0].arn
    }
  }

  tags = var.tags

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}

resource "aws_iam_role" "eks_nodes" {
  count = var.include_eks ? 1 : 0

  name = "${var.name}-eks-nodes"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_nodes" {
  for_each = var.include_eks ? toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]) : []

  role       = aws_iam_role.eks_nodes[0].name
  policy_arn = each.value
}

resource "aws_eks_node_group" "default" {
  count = var.include_eks ? 1 : 0

  cluster_name    = aws_eks_cluster.this[0].name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.eks_nodes[0].arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = ["t3.medium"]

  scaling_config {
    min_size     = 1
    max_size     = 3
    desired_size = 2
  }

  tags = var.tags

  # Nodes need the NAT route to pull images and join the cluster.
  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes,
    aws_route.private_nat,
  ]
}

# -----------------------------------------------------------------------------
# RDS PostgreSQL (optional)
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  count = var.include_rds ? 1 : 0

  name       = var.name
  subnet_ids = aws_subnet.private[*].id

  tags = var.tags
}

resource "aws_security_group" "rds" {
  count = var.include_rds ? 1 : 0

  name        = "${var.name}-rds"
  description = "PostgreSQL of the ${var.name} sandbox"
  vpc_id      = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-rds"
  })
}

resource "aws_vpc_security_group_ingress_rule" "rds_postgres" {
  count = var.include_rds ? 1 : 0

  security_group_id = aws_security_group.rds[0].id
  description       = "PostgreSQL from inside the VPC"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
}

resource "aws_db_instance" "this" {
  count = var.include_rds ? 1 : 0

  identifier = var.name

  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = local.database_name
  username = "sandbox_admin"
  # RDS generates the master password and keeps it in Secrets Manager.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this[0].name
  vpc_security_group_ids = [aws_security_group.rds[0].id]
  publicly_accessible    = false

  iam_database_authentication_enabled = true
  performance_insights_enabled        = true
  backup_retention_period             = 7
  auto_minor_version_upgrade          = true
  copy_tags_to_snapshot               = true

  # A sandbox is meant to be thrown away: no final snapshot, no deletion lock.
  skip_final_snapshot = true
  deletion_protection = false

  tags = var.tags
}
