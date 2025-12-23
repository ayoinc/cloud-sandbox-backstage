terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  
  backend "s3" {
    # Configure your backend
    # bucket = "your-terraform-state-bucket"
    # key    = "${{ values.name }}/terraform.tfstate"
    # region = "${{ values.region }}"
  }
}

provider "aws" {
  region = var.region
  
  default_tags {
    tags = {
      Project     = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "${{ values.owner }}"
    }
  }
}

# Get existing VPC (assumes VPC already exists)
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

# Random password for master user
resource "random_password" "master" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store password in Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.name}-${var.environment}-db-credentials"
  description = "Database credentials for ${var.name}"
  
  tags = {
    Name = "${var.name}-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    host     = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    database = var.database_name
  })
}

# Security Group
resource "aws_security_group" "rds" {
  name        = "${var.name}-${var.environment}-rds-sg"
  description = "Security group for RDS instance ${var.name}"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "Database port"
    from_port   = var.engine == "postgres" ? 5432 : 3306
    to_port     = var.engine == "postgres" ? 5432 : 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-rds-sg"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-${var.environment}-subnet-group"
  subnet_ids = data.aws_subnets.private.ids

  tags = {
    Name = "${var.name}-subnet-group"
  }
}

# Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.name}-${var.environment}-params"
  family = "${var.engine}${var.engine_version}"

  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [1] : []
    content {
      name  = "log_statement"
      value = "all"
    }
  }

  tags = {
    Name = "${var.name}-params"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.name}-${var.environment}"
  
  # Engine
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  
  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true
  
  # Database
  db_name  = var.database_name
  username = var.master_username
  password = random_password.master.result
  port     = var.engine == "postgres" ? 5432 : 3306
  
  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = var.multi_az
  
  # Backup
  backup_retention_period = var.environment == "production" ? 30 : 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  
  # Monitoring
  performance_insights_enabled    = var.environment != "development"
  monitoring_interval             = var.environment != "development" ? 60 : 0
  monitoring_role_arn             = var.environment != "development" ? aws_iam_role.rds_monitoring[0].arn : null
  enabled_cloudwatch_logs_exports = var.engine == "postgres" ? ["postgresql", "upgrade"] : ["error", "slowquery"]
  
  # Maintenance
  auto_minor_version_upgrade = true
  deletion_protection        = var.environment == "production"
  skip_final_snapshot        = var.environment != "production"
  final_snapshot_identifier  = var.environment == "production" ? "${var.name}-final-snapshot" : null
  
  parameter_group_name = aws_db_parameter_group.main.name

  tags = {
    Name        = var.name
    Description = var.description
  }
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  count = var.environment != "development" ? 1 : 0
  name  = "${var.name}-${var.environment}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.environment != "development" ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
