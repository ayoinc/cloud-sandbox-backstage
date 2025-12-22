terraform {
  required_version = ">= 1.0"
  
  required_providers {
    {%- if values.cloud_provider == "aws" %}
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    {%- elif values.cloud_provider == "azure" %}
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    {%- elif values.cloud_provider == "gcp" %}
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    {%- endif %}
  }
}

{%- if values.cloud_provider == "aws" %}
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.name
    }
  }
}
{%- elif values.cloud_provider == "azure" %}
provider "azurerm" {
  features {}
}
{%- elif values.cloud_provider == "gcp" %}
provider "google" {
  project = var.project_id
  region  = var.region
}
{%- endif %}

variable "name" {
  default = "${{ values.name }}"
}

variable "region" {
  default = "${{ values.region }}"
}

variable "environment" {
  default = "${{ values.environment }}"
}

variable "vpc_cidr" {
  default = "${{ values.vpc_cidr }}"
}

{%- if values.cloud_provider == "aws" %}
# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  public_subnets  = [for i in range(${{ values.public_subnets }}) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets = [for i in range(${{ values.private_subnets }}) : cidrsubnet(var.vpc_cidr, 8, i + 10)]

  enable_nat_gateway = ${{ values.private_subnets }} > 0
  single_nat_gateway = true

  tags = {
    Environment = var.environment
  }
}

{%- if values.include_bastion %}
# Bastion Host
module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name          = "${var.name}-bastion"
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnets[0]

  vpc_security_group_ids = [aws_security_group.bastion.id]

  tags = {
    Role = "bastion"
  }
}

resource "aws_security_group" "bastion" {
  name_prefix = "${var.name}-bastion-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
{%- endif %}

{%- if values.include_eks %}
# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.name
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      min_size     = 1
      max_size     = 3
      desired_size = 2
      instance_types = ["t3.medium"]
    }
  }
}
{%- endif %}

{%- if values.include_rds %}
# RDS Database
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = var.name

  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"

  allocated_storage = 20

  db_name  = replace(var.name, "-", "_")
  username = "admin"

  vpc_security_group_ids = [aws_security_group.rds.id]
  subnet_ids             = module.vpc.private_subnets

  family               = "postgres15"
  major_engine_version = "15"

  deletion_protection = false
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.name}-rds-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}
{%- endif %}
{%- endif %}

output "vpc_id" {
  value = module.vpc.vpc_id
}
