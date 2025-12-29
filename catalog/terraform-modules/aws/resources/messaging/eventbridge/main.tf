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
  name_prefix    = "${var.project_name}-${var.environment}"
  use_custom_bus = var.event_bus_name != null
  event_bus_name = local.use_custom_bus ? aws_cloudwatch_event_bus.this[0].name : "default"
  event_bus_arn  = local.use_custom_bus ? aws_cloudwatch_event_bus.this[0].arn : "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:event-bus/default"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  # Flatten targets for IAM policy creation
  all_targets = flatten([
    for rule in var.rules : [
      for target in rule.targets : {
        rule_name  = rule.name
        target_arn = target.arn
        type       = target.type
      }
    ]
  ])

  lambda_targets        = [for t in local.all_targets : t.target_arn if t.type == "lambda"]
  sqs_targets           = [for t in local.all_targets : t.target_arn if t.type == "sqs"]
  sns_targets           = [for t in local.all_targets : t.target_arn if t.type == "sns"]
  step_function_targets = [for t in local.all_targets : t.target_arn if t.type == "step_function"]
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

################################################################################
# Event Bus
################################################################################

resource "aws_cloudwatch_event_bus" "this" {
  count = local.use_custom_bus ? 1 : 0

  name = var.event_bus_name

  tags = merge(
    local.common_tags,
    {
      Name = var.event_bus_name
    }
  )
}

################################################################################
# Event Rules
################################################################################

resource "aws_cloudwatch_event_rule" "this" {
  for_each = { for rule in var.rules : rule.name => rule }

  name                = "${local.name_prefix}-${each.value.name}"
  description         = each.value.description
  event_bus_name      = local.event_bus_name
  schedule_expression = each.value.schedule_expression
  event_pattern       = each.value.event_pattern
  state               = each.value.state

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-${each.value.name}"
    }
  )
}

################################################################################
# Event Targets
################################################################################

resource "aws_cloudwatch_event_target" "this" {
  for_each = {
    for item in flatten([
      for rule in var.rules : [
        for idx, target in rule.targets : {
          key             = "${rule.name}-${idx}"
          rule_name       = rule.name
          target_id       = target.id
          arn             = target.arn
          type            = target.type
          input           = target.input
          input_path      = target.input_path
          role_arn        = target.role_arn
          dead_letter_arn = target.dead_letter_arn
        }
      ]
    ]) : item.key => item
  }

  rule           = aws_cloudwatch_event_rule.this[each.value.rule_name].name
  event_bus_name = local.event_bus_name
  target_id      = each.value.target_id
  arn            = each.value.arn
  input          = each.value.input
  input_path     = each.value.input_path
  role_arn       = each.value.type == "step_function" ? (each.value.role_arn != null ? each.value.role_arn : aws_iam_role.eventbridge[0].arn) : each.value.role_arn

  dynamic "dead_letter_config" {
    for_each = each.value.dead_letter_arn != null ? [1] : []
    content {
      arn = each.value.dead_letter_arn
    }
  }
}

################################################################################
# Event Archive
################################################################################

resource "aws_cloudwatch_event_archive" "this" {
  count = var.enable_archive && local.use_custom_bus ? 1 : 0

  name             = "${local.name_prefix}-archive"
  event_source_arn = aws_cloudwatch_event_bus.this[0].arn
  retention_days   = var.archive_retention_days > 0 ? var.archive_retention_days : null
}

################################################################################
# IAM Role for EventBridge
################################################################################

resource "aws_iam_role" "eventbridge" {
  count = length(local.step_function_targets) > 0 ? 1 : 0

  name = "${local.name_prefix}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-eventbridge-role"
    }
  )
}

resource "aws_iam_role_policy" "eventbridge_step_functions" {
  count = length(local.step_function_targets) > 0 ? 1 : 0

  name = "${local.name_prefix}-step-functions-policy"
  role = aws_iam_role.eventbridge[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "states:StartExecution"
        Resource = local.step_function_targets
      }
    ]
  })
}

################################################################################
# Lambda Permissions
################################################################################

resource "aws_lambda_permission" "eventbridge" {
  for_each = toset(local.lambda_targets)

  statement_id  = "AllowEventBridgeInvoke-${md5(each.value)}"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "events.amazonaws.com"
  source_arn    = local.event_bus_arn
}

################################################################################
# SQS Queue Policies
################################################################################

data "aws_iam_policy_document" "sqs" {
  for_each = toset(local.sqs_targets)

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [each.value]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [for rule in aws_cloudwatch_event_rule.this : rule.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "eventbridge" {
  for_each = toset(local.sqs_targets)

  queue_url = replace(replace(each.value, "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:", "https://sqs.${data.aws_region.current.name}.amazonaws.com/${data.aws_caller_identity.current.account_id}/"), ":", "/")
  policy    = data.aws_iam_policy_document.sqs[each.value].json
}

################################################################################
# SNS Topic Policies
################################################################################

data "aws_iam_policy_document" "sns" {
  for_each = toset(local.sns_targets)

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["sns:Publish"]
    resources = [each.value]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [for rule in aws_cloudwatch_event_rule.this : rule.arn]
    }
  }
}

resource "aws_sns_topic_policy" "eventbridge" {
  for_each = toset(local.sns_targets)

  arn    = each.value
  policy = data.aws_iam_policy_document.sns[each.value].json
}
