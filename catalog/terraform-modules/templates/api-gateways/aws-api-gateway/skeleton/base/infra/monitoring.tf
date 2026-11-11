locals {
  alarm_actions = var.alarm_topic_arn != "" ? [var.alarm_topic_arn] : []

  api_dimensions    = { ApiName = var.api_name, Stage = local.stage_name }
  lambda_dimensions = { FunctionName = var.api_name }

  dashboard_metrics = {
    Requests           = [["AWS/ApiGateway", "Count", "ApiName", var.api_name, "Stage", local.stage_name, { stat = "Sum" }]]
    Errors             = [for m in ["4XXError", "5XXError"] : ["AWS/ApiGateway", m, "ApiName", var.api_name, "Stage", local.stage_name, { stat = "Sum" }]]
    "Latency (ms)"     = [for s in ["p50", "p95", "p99"] : ["AWS/ApiGateway", "Latency", "ApiName", var.api_name, "Stage", local.stage_name, { stat = s }]]
    "Function"         = [for m in ["Invocations", "Errors", "Throttles"] : ["AWS/Lambda", m, "FunctionName", var.api_name, { stat = "Sum" }]]
    "Function time ms" = [for s in ["p50", "p95", "p99"] : ["AWS/Lambda", "Duration", "FunctionName", var.api_name, { stat = s }]]
  }
}

# The role API Gateway assumes to write execution and access logs. It is an
# account setting of the region, shared by every API in it.
module "apigateway_logs_role" {
  count  = var.enable_monitoring && var.manage_account_logging_role ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/core/iam-role?ref=83f9ff7222d2731d5cc0da4ab1fc1f7c46da3693"

  name                = "${var.api_name}-apigateway-logs"
  description         = "Lets API Gateway write to CloudWatch Logs"
  trusted_services    = ["apigateway.amazonaws.com"]
  managed_policy_arns = ["${local.managed_policy}/service-role/AmazonAPIGatewayPushToCloudWatchLogs"]

  tags = local.tags
}

resource "aws_api_gateway_account" "this" {
  count = var.enable_monitoring && var.manage_account_logging_role ? 1 : 0

  cloudwatch_role_arn = module.apigateway_logs_role[0].role_arn
}

# Access log group, alarms and dashboard of the API.
module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/monitoring/cloudwatch?ref=83f9ff7222d2731d5cc0da4ab1fc1f7c46da3693"

  project_name      = var.api_name
  environment       = local.stage_name
  log_group_name    = "/aws/apigateway/${var.api_name}/access"
  retention_in_days = var.log_retention_days

  alarms = [
    {
      name                = "${var.api_name}-api-5xx"
      namespace           = "AWS/ApiGateway"
      metric_name         = "5XXError"
      dimensions          = local.api_dimensions
      statistic           = "Sum"
      period              = 300
      evaluation_periods  = 1
      comparison_operator = "GreaterThanThreshold"
      threshold           = 5
      alarm_actions       = local.alarm_actions
    },
    {
      name                = "${var.api_name}-api-latency"
      namespace           = "AWS/ApiGateway"
      metric_name         = "Latency"
      dimensions          = local.api_dimensions
      statistic           = "Average"
      period              = 300
      evaluation_periods  = 3
      comparison_operator = "GreaterThanThreshold"
      threshold           = 2000
      alarm_actions       = local.alarm_actions
    },
    {
      name                = "${var.api_name}-lambda-errors"
      namespace           = "AWS/Lambda"
      metric_name         = "Errors"
      dimensions          = local.lambda_dimensions
      statistic           = "Sum"
      period              = 300
      evaluation_periods  = 1
      comparison_operator = "GreaterThanThreshold"
      threshold           = 5
      alarm_actions       = local.alarm_actions
    },
    {
      name                = "${var.api_name}-lambda-throttles"
      namespace           = "AWS/Lambda"
      metric_name         = "Throttles"
      dimensions          = local.lambda_dimensions
      statistic           = "Sum"
      period              = 300
      evaluation_periods  = 1
      comparison_operator = "GreaterThanThreshold"
      threshold           = 0
      alarm_actions       = local.alarm_actions
    },
  ]

  create_dashboard = true
  dashboard_name   = var.api_name
  dashboard_body = jsonencode({
    widgets = [
      for i, title in keys(local.dashboard_metrics) : {
        type   = "metric"
        x      = (i % 2) * 12
        y      = floor(i / 2) * 6
        width  = 12
        height = 6
        properties = {
          title   = title
          region  = var.aws_region
          view    = "timeSeries"
          period  = 300
          metrics = local.dashboard_metrics[title]
        }
      }
    ]
  })

  tags = local.tags
}
