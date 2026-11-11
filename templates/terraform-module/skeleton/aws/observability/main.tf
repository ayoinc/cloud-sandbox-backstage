# -----------------------------------------------------------------------------
# AWS Observability Module - Main Resources
# -----------------------------------------------------------------------------

data "aws_region" "current" {}

locals {
  # Lowercase, hyphen-separated and short enough for every AWS name limit.
  project     = trimsuffix(substr(replace(lower(var.project_name), "/[^a-z0-9]+/", "-"), 0, 23), "-")
  name_prefix = "${local.project}-${var.environment}"

  # Log groups and custom metrics of the project live under this path.
  path_prefix = "${local.project}/${var.environment}"

  # The compute and database modules name their resources after the prefix.
  autoscaling_group_name = coalesce(var.autoscaling_group_name, "${local.name_prefix}-asg")
  db_instance_identifier = coalesce(var.db_instance_identifier, "${local.name_prefix}-db")

  alarm_email = var.alarm_email == null ? "" : var.alarm_email
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/${local.path_prefix}/application"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

# Additional Log Groups
resource "aws_cloudwatch_log_group" "system" {
  name              = "/${local.path_prefix}/system"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "security" {
  name              = "/${local.path_prefix}/security"
  retention_in_days = var.security_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

# -----------------------------------------------------------------------------
# CloudWatch Dashboard
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  count = var.enable_dashboard ? 1 : 0

  dashboard_name = local.name_prefix

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${local.name_prefix} dashboard"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", local.autoscaling_group_name, { stat = "Average" }]
          ]
          period = 300
          region = data.aws_region.current.region
          title  = "EC2 CPU Utilization"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 1
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", local.autoscaling_group_name, { stat = "Average" }],
            ["AWS/EC2", "NetworkOut", "AutoScalingGroupName", local.autoscaling_group_name, { stat = "Average" }]
          ]
          period = 300
          region = data.aws_region.current.region
          title  = "EC2 Network I/O"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", local.db_instance_identifier, { stat = "Average" }]
          ]
          period = 300
          region = data.aws_region.current.region
          title  = "RDS CPU Utilization"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 7
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", local.db_instance_identifier, { stat = "Average" }]
          ]
          period = 300
          region = data.aws_region.current.region
          title  = "RDS Connections"
          view   = "timeSeries"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 13
        width  = 24
        height = 6
        properties = {
          query  = "SOURCE '/${local.path_prefix}/application' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region = data.aws_region.current.region
          title  = "Application Logs"
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms
# -----------------------------------------------------------------------------

# SNS Topic for Alarms
resource "aws_sns_topic" "alarms" {
  count = var.enable_alarms ? 1 : 0

  name              = "${local.name_prefix}-alarms"
  kms_master_key_id = var.kms_key_arn

  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count = var.enable_alarms && local.alarm_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = local.alarm_email
}

# High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "CPU utilization exceeds ${var.cpu_alarm_threshold}%"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]
  ok_actions          = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    AutoScalingGroupName = local.autoscaling_group_name
  }

  tags = var.tags
}

# High Memory Alarm (CloudWatch agent metric aggregated per Auto Scaling group)
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = local.path_prefix
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold
  alarm_description   = "Memory utilization exceeds ${var.memory_alarm_threshold}%"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]
  ok_actions          = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    AutoScalingGroupName = local.autoscaling_group_name
  }

  tags = var.tags
}

# RDS High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_cpu_alarm_threshold
  alarm_description   = "RDS CPU utilization exceeds ${var.rds_cpu_alarm_threshold}%"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]
  ok_actions          = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    DBInstanceIdentifier = local.db_instance_identifier
  }

  tags = var.tags
}

# RDS Low Storage Alarm
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_storage_alarm_threshold * 1024 * 1024 * 1024 # GB to bytes
  alarm_description   = "RDS free storage below ${var.rds_storage_alarm_threshold}GB"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]
  ok_actions          = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    DBInstanceIdentifier = local.db_instance_identifier
  }

  tags = var.tags
}

# Error Log Alarm
resource "aws_cloudwatch_metric_alarm" "error_logs" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ErrorCount"
  namespace           = local.path_prefix
  period              = 300
  statistic           = "Sum"
  threshold           = var.error_log_threshold
  alarm_description   = "Error count exceeds ${var.error_log_threshold} in 5 minutes"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]
  treat_missing_data  = "notBreaching"

  tags = var.tags
}

# -----------------------------------------------------------------------------
# CloudWatch Log Metric Filters
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "${local.name_prefix}-errors"
  pattern        = "?ERROR ?Error ?error ?FATAL ?Fatal ?fatal"
  log_group_name = aws_cloudwatch_log_group.main.name

  metric_transformation {
    name          = "ErrorCount"
    namespace     = local.path_prefix
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "warnings" {
  name           = "${local.name_prefix}-warnings"
  pattern        = "?WARN ?Warning ?warning"
  log_group_name = aws_cloudwatch_log_group.main.name

  metric_transformation {
    name          = "WarningCount"
    namespace     = local.path_prefix
    value         = "1"
    default_value = "0"
  }
}

# -----------------------------------------------------------------------------
# X-Ray
# -----------------------------------------------------------------------------

resource "aws_xray_sampling_rule" "main" {
  count = var.enable_xray ? 1 : 0

  rule_name      = substr(local.name_prefix, 0, 32)
  priority       = 1000
  version        = 1
  reservoir_size = 5
  fixed_rate     = 0.05
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = local.name_prefix
  resource_arn   = "*"

  tags = var.tags
}

