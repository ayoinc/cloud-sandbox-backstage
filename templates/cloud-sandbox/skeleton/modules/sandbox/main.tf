# =============================================================================
# Cloud Sandbox Module - Main
# =============================================================================
# Creates a complete sandbox environment with VPC, optional bastion,
# optional EKS cluster, and optional RDS database.
# =============================================================================

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  public_subnets  = [for i in range(var.public_subnets) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets = [for i in range(var.private_subnets) : cidrsubnet(var.vpc_cidr, 8, i + 10)]

  enable_nat_gateway = var.private_subnets > 0
  single_nat_gateway = true

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# -----------------------------------------------------------------------------
# Bastion Host (Optional)
# -----------------------------------------------------------------------------
module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  count = var.include_bastion ? 1 : 0

  name          = "${var.name}-bastion"
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnets[0]

  vpc_security_group_ids = [module.bastion_sg[0].security_group_id]

  tags = merge(var.tags, {
    Role = "bastion"
  })
}

module "bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  count = var.include_bastion ? 1 : 0

  name        = "${var.name}-bastion"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp"]
  egress_rules        = ["all-all"]

  tags = var.tags
}

# -----------------------------------------------------------------------------
# EKS Cluster (Optional)
# -----------------------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  count = var.include_eks ? 1 : 0

  cluster_name    = var.name
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# RDS Database (Optional)
# -----------------------------------------------------------------------------
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  count = var.include_rds ? 1 : 0

  identifier = var.name

  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"

  allocated_storage = 20

  db_name  = replace(var.name, "-", "_")
  username = "admin"

  vpc_security_group_ids = [module.rds_sg[0].security_group_id]
  subnet_ids             = module.vpc.private_subnets
  create_db_subnet_group = true

  family               = "postgres15"
  major_engine_version = "15"

  deletion_protection = false

  tags = var.tags
}

module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  count = var.include_rds ? 1 : 0

  name        = "${var.name}-rds"
  description = "Security group for RDS"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [var.vpc_cidr]
  ingress_rules       = ["postgresql-tcp"]
  egress_rules        = ["all-all"]

  tags = var.tags
}
