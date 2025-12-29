terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket = "${{ values.projectName }}-terraform-state"
    key    = "${{ values.environment }}/terraform.tfstate"
    region = "${{ values.region }}"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  name_prefix = "${{ values.projectName }}-${{ values.environment }}"
  
  common_tags = {
    Project     = "${{ values.projectName }}"
    Environment = "${{ values.environment }}"
    ManagedBy   = "terraform"
    Repository  = "${{ values.projectName }}-infrastructure"
  }
}

# VPC Module
module "vpc" {
  source = "../../aws/resources/network/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr

  public_subnets = [
    { cidr = cidrsubnet(var.vpc_cidr, 4, 0), az = "${var.region}a" },
    { cidr = cidrsubnet(var.vpc_cidr, 4, 1), az = "${var.region}b" },
    { cidr = cidrsubnet(var.vpc_cidr, 4, 2), az = "${var.region}c" }
  ]

  private_subnets = [
    { cidr = cidrsubnet(var.vpc_cidr, 4, 4), az = "${var.region}a" },
    { cidr = cidrsubnet(var.vpc_cidr, 4, 5), az = "${var.region}b" },
    { cidr = cidrsubnet(var.vpc_cidr, 4, 6), az = "${var.region}c" }
  ]

  database_subnets = [
    { cidr = cidrsubnet(var.vpc_cidr, 4, 8), az = "${var.region}a" },
    { cidr = cidrsubnet(var.vpc_cidr, 4, 9), az = "${var.region}b" },
    { cidr = cidrsubnet(var.vpc_cidr, 4, 10), az = "${var.region}c" }
  ]

  enable_nat_gateway = true
  single_nat_gateway = var.environment != "production"

  tags = local.common_tags
}

# Application Load Balancer
module "alb" {
  source = "../../aws/resources/network/alb"

  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnet_ids
  security_groups = [aws_security_group.alb.id]

  certificate_arn = var.certificate_arn
  
  target_group_port     = 80
  target_group_protocol = "HTTP"
  target_type           = "${{ values.computeType }}" == "ec2-asg" ? "instance" : "ip"
  
  health_check_path = "/health"

  tags = local.common_tags
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
  })
}

{%- if values.computeType == "ecs-fargate" or values.computeType == "ecs-ec2" %}
# ECS Cluster and Service
module "ecs" {
  source = "../../aws/resources/compute/ecs"

  project_name   = var.project_name
  environment    = var.environment
  cluster_name   = "${local.name_prefix}-cluster"
  
  enable_container_insights = true
  
  task_family              = "${local.name_prefix}-app"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  requires_compatibilities = ["${{ values.computeType }}" == "ecs-fargate" ? "FARGATE" : "EC2"]
  
  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn
  
  container_definitions = jsonencode([{
    name  = "app"
    image = var.container_image
    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.app.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "app"
      }
    }
  }])

  service_name   = "${local.name_prefix}-service"
  desired_count  = var.min_capacity
  subnets        = module.vpc.private_subnet_ids
  security_groups = [aws_security_group.app.id]
  assign_public_ip = false
  
  target_group_arn = module.alb.target_group_arn
  container_name   = "app"
  container_port   = 80

  tags = local.common_tags
}
{%- endif %}

{%- if values.computeType == "ec2-asg" %}
# Auto Scaling Group
module "asg" {
  source = "../../aws/resources/compute/asg"

  project_name      = var.project_name
  environment       = var.environment
  
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  
  min_size          = var.min_capacity
  max_size          = var.max_capacity
  desired_capacity  = var.min_capacity
  
  vpc_zone_identifier = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.app.id]
  
  target_group_arns = [module.alb.target_group_arn]
  
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tags = local.common_tags
}
{%- endif %}

# Security Group for Application
resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Security group for application"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-sg"
  })
}

# RDS Database
module "rds" {
  source = "../../aws/resources/database/rds"

  project_name = var.project_name
  environment  = var.environment

  engine         = "${{ values.databaseEngine }}"
  engine_version = var.database_engine_version
  instance_class = "${{ values.databaseInstanceClass }}"
  
  allocated_storage     = var.database_allocated_storage
  max_allocated_storage = var.database_max_allocated_storage

  database_name   = replace(var.project_name, "-", "_")
  master_username = var.database_username
  master_password = var.database_password

  multi_az               = ${{ values.multiAz }}
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.database.id]

  backup_retention_period = var.environment == "production" ? 30 : 7
  skip_final_snapshot     = var.environment != "production"

  tags = local.common_tags
}

# Security Group for Database
resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-db-sg"
  description = "Security group for RDS database"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = ${{ values.databaseEngine == "postgres" and "5432" or "3306" }}
    to_port         = ${{ values.databaseEngine == "postgres" and "5432" or "3306" }}
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-sg"
  })
}

{%- if values.enableWaf %}
# WAF Web ACL
module "waf" {
  source = "../../aws/resources/security/waf"

  project_name = var.project_name
  environment  = var.environment
  
  name  = "${local.name_prefix}-waf"
  scope = "REGIONAL"

  managed_rule_groups = [
    {
      name        = "AWSManagedRulesCommonRuleSet"
      vendor_name = "AWS"
      priority    = 10
    },
    {
      name        = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name = "AWS"
      priority    = 20
    },
    {
      name        = "AWSManagedRulesSQLiRuleSet"
      vendor_name = "AWS"
      priority    = 30
    }
  ]

  tags = local.common_tags
}

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = module.alb.lb_arn
  web_acl_arn  = module.waf.web_acl_arn
}
{%- endif %}

{%- if values.enableCloudfront %}
# CloudFront Distribution
module "cloudfront" {
  source = "../../aws/resources/network/cloudfront"

  project_name = var.project_name
  environment  = var.environment

  origin_domain_name = module.alb.lb_dns_name
  origin_id          = "${local.name_prefix}-alb"
  origin_type        = "custom"

  viewer_protocol_policy = "redirect-to-https"
  
  aliases         = var.cloudfront_aliases
  certificate_arn = var.cloudfront_certificate_arn

  tags = local.common_tags
}
{%- endif %}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/${local.name_prefix}/app"
  retention_in_days = var.environment == "production" ? 90 : 30

  tags = local.common_tags
}

# IAM Roles for ECS
resource "aws_iam_role" "ecs_execution" {
  name = "${local.name_prefix}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}
