# -----------------------------------------------------------------------------
# AWS Security Module - Main Resources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  # Lowercase, hyphen-separated and short enough for every AWS name limit.
  project     = trimsuffix(substr(replace(lower(var.project_name), "/[^a-z0-9]+/", "-"), 0, 23), "-")
  name_prefix = "${local.project}-${var.environment}"

  # Secrets and log groups of the project live under this path.
  path_prefix = "${local.project}/${var.environment}"

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region
  partition  = data.aws_partition.current.partition

  waf_managed_rule_groups = [
    "AWSManagedRulesCommonRuleSet",
    "AWSManagedRulesKnownBadInputsRuleSet",
    "AWSManagedRulesSQLiRuleSet",
  ]
}

# KMS Key for encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for ${local.name_prefix}"
  deletion_window_in_days = var.environment == "prod" ? 30 : 7
  enable_key_rotation     = true
  multi_region            = var.kms_multi_region

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableIamPolicies"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${local.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:${local.partition}:logs:${local.region}:${local.account_id}:*"
          }
        }
      },
      {
        Sid    = "AllowCloudWatchAlarmsToEncryptedTopics"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-kms"
  })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.name_prefix}"
  target_key_id = aws_kms_key.main.key_id
}

# -----------------------------------------------------------------------------
# IAM Roles
# -----------------------------------------------------------------------------

# Application Role
resource "aws_iam_role" "application" {
  name = "${local.name_prefix}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com", "lambda.amazonaws.com"]
        }
      }
    ]
  })

  tags = var.tags
}

# Application Policy - Secrets Manager access
resource "aws_iam_role_policy" "secrets_access" {
  name = "secrets-access"
  role = aws_iam_role.application.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:${local.partition}:secretsmanager:${local.region}:${local.account_id}:secret:${local.path_prefix}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.main.arn
      }
    ]
  })
}

# Application Policy - S3 access to the project's buckets
resource "aws_iam_role_policy" "s3_access" {
  name = "s3-access"
  role = aws_iam_role.application.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:${local.partition}:s3:::${local.name_prefix}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:${local.partition}:s3:::${local.name_prefix}-*/*"
      }
    ]
  })
}

# Application Policy - CloudWatch Logs
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "cloudwatch-logs"
  role = aws_iam_role.application.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:/${local.path_prefix}/*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Secrets Manager - Application Secrets
# -----------------------------------------------------------------------------

resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

resource "random_password" "app_secret" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "${local.path_prefix}/app-secrets"
  description             = "Generated application secrets for ${local.name_prefix}"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0
  kms_key_id              = aws_kms_key.main.arn

  tags = var.tags
}

# Seeds the secret with generated values; later changes made outside Terraform
# (rotation, extra keys) are kept.
resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    JWT_SECRET = random_password.jwt_secret.result
    APP_SECRET = random_password.app_secret.result
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# -----------------------------------------------------------------------------
# Security Group - Bastion/Jump Host
# -----------------------------------------------------------------------------

data "aws_vpc" "bastion" {
  count = var.enable_bastion_sg ? 1 : 0

  id = var.vpc_id
}

resource "aws_security_group" "bastion" {
  count = var.enable_bastion_sg ? 1 : 0

  name_prefix = "${local.name_prefix}-bastion-"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-bastion-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  count = var.enable_bastion_sg ? length(var.bastion_allowed_cidrs) : 0

  security_group_id = aws_security_group.bastion[0].id
  description       = "SSH from an allowed network"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.bastion_allowed_cidrs[count.index]

  tags = var.tags
}

# The bastion only needs to open SSH sessions to hosts inside its VPC.
resource "aws_vpc_security_group_egress_rule" "bastion_ssh" {
  count = var.enable_bastion_sg ? 1 : 0

  security_group_id = aws_security_group.bastion[0].id
  description       = "SSH to hosts inside the VPC"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = data.aws_vpc.bastion[0].cidr_block

  tags = var.tags
}

# -----------------------------------------------------------------------------
# AWS WAF Web ACL (regional: ALB, API Gateway, AppSync)
# -----------------------------------------------------------------------------

resource "aws_wafv2_web_acl" "main" {
  count = var.enable_waf ? 1 : 0

  name        = "${local.name_prefix}-waf"
  description = "WAF rules for ${local.name_prefix}"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = local.waf_managed_rule_groups
    content {
      name     = rule.value
      priority = rule.key + 1

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value
        sampled_requests_enabled   = true
      }
    }
  }

  rule {
    name     = "RateLimitRule"
    priority = length(local.waf_managed_rule_groups) + 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}
