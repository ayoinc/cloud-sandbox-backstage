terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  topic_name = var.fifo_topic ? "${var.project_name}-${var.environment}-${var.topic_name}.fifo" : "${var.project_name}-${var.environment}-${var.topic_name}"

  default_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_sns_topic" "this" {
  name                        = local.topic_name
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : null
  kms_master_key_id           = var.kms_master_key_id
  delivery_policy             = var.delivery_policy

  tags = merge(local.default_tags, var.tags)
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "topic_policy" {
  statement {
    sid    = "DefaultTopicPolicy"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "sns:GetTopicAttributes",
      "sns:SetTopicAttributes",
      "sns:AddPermission",
      "sns:RemovePermission",
      "sns:DeleteTopic",
      "sns:Subscribe",
      "sns:ListSubscriptionsByTopic",
      "sns:Publish"
    ]

    resources = [aws_sns_topic.this.arn]
  }

  dynamic "statement" {
    for_each = length(var.allowed_aws_services) > 0 ? [1] : []

    content {
      sid    = "AllowAWSServices"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = var.allowed_aws_services
      }

      actions = [
        "sns:Publish"
      ]

      resources = [aws_sns_topic.this.arn]
    }
  }
}

resource "aws_sns_topic_policy" "this" {
  arn    = aws_sns_topic.this.arn
  policy = data.aws_iam_policy_document.topic_policy.json
}

resource "aws_sns_topic_subscription" "this" {
  for_each = { for idx, sub in var.subscriptions : idx => sub }

  topic_arn     = aws_sns_topic.this.arn
  protocol      = each.value.protocol
  endpoint      = each.value.endpoint
  filter_policy = each.value.filter_policy

  endpoint_auto_confirms = contains(["http", "https"], each.value.protocol) ? true : null
}
