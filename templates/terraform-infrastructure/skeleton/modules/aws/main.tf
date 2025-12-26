# AWS Infrastructure Module
# This module provisions AWS resources for the infrastructure stack

{% if values.enable_networking %}
# VPC and Networking
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 4, i + length(var.availability_zones))]

  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "production"
  enable_dns_hostnames   = true
  enable_dns_support     = true

  tags = var.common_tags
}
{% endif %}

{% if values.enable_kubernetes %}
# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "${var.name_prefix}-eks"
  cluster_version = var.kubernetes_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      name           = "${var.name_prefix}-node-group"
      instance_types = [var.node_instance_type]
      min_size       = var.min_nodes
      max_size       = var.max_nodes
      desired_size   = var.min_nodes
    }
  }

  tags = var.common_tags
}
{% endif %}

{% if values.enable_database %}
# RDS Database
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${var.name_prefix}-db"

  engine               = "postgres"
  engine_version       = "15"
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = var.environment == "production" ? "db.r5.large" : "db.t3.medium"

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = replace(var.name_prefix, "-", "_")
  username = "admin"
  password = var.database_password
  port     = 5432

  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_ids             = module.vpc.private_subnets
  db_subnet_group_name   = "${var.name_prefix}-subnet-group"

  backup_retention_period = var.enable_backup ? 7 : 0
  deletion_protection     = var.environment == "production"

  tags = var.common_tags
}
{% endif %}

{% if values.enable_storage %}
# S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket = "${var.name_prefix}-storage-${var.environment}"

  tags = var.common_tags
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.enable_kms ? "aws:kms" : "AES256"
    }
  }
}
{% endif %}

{% if values.enable_kms %}
# KMS Key
resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.name_prefix}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.common_tags
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.name_prefix}"
  target_key_id = aws_kms_key.main.key_id
}
{% endif %}

{% if values.enable_secrets_manager %}
# Secrets Manager
resource "aws_secretsmanager_secret" "main" {
  name        = "${var.name_prefix}-secrets"
  description = "Secrets for ${var.name_prefix}"

  tags = var.common_tags
}
{% endif %}

{% if values.enable_monitoring %}
# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/${var.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}
{% endif %}
