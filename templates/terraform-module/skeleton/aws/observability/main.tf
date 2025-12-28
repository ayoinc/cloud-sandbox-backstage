# -----------------------------------------------------------------------------
# AWS Observability Module - Main Resources
# -----------------------------------------------------------------------------

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/${var.project_name}/${var.environment}/application"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

# Additional Log Groups
resource "aws_cloudwatch_log_group" "system" {
  name              = "/${var.project_name}/${var.environment}/system"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "security" {
  name              = "/${var.project_name}/${var.environment}/security"
  retention_in_days = var.security_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

# -----------------------------------------------------------------------------
# CloudWatch Dashboard
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  count = var.enable_dashboard ? 1 : 0

  dashboard_name = "${var.project_name}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${var.project_name} - ${var.environment} Dashboard"
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
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${var.project_name}-${var.environment}-asg", { stat = "Average" }]
          ]
          period = 300
          region = data.aws_region.current.name
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
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", "${var.project_name}-${var.environment}-asg", { stat = "Average" }],
            ["AWS/EC2", "NetworkOut", "AutoScalingGroupName", "${var.project_name}-${var.environment}-asg", { stat = "Average" }]
          ]
          period = 300
          region = data.aws_region.current.name
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
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.project_name}-${var.environment}-db", { stat = "Average" }]
          ]
          period = 300
          region = data.aws_region.current.name
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
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${var.project_name}-${var.environment}-db", { stat = "Average" }]
          ]
          period = 300
          region = data.aws_region.current.name
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
          query  = "SOURCE '/${var.project_name}/${var.environment}/application' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region = data.aws_region.current.name
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

  name              = "${var.project_name}-${var.environment}-alarms"
  kms_master_key_id = var.kms_key_arn

  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count = var.enable_alarms && var.alarm_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
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
    AutoScalingGroupName = "${var.project_name}-${var.environment}-asg"
  }

  tags = var.tags
}

# High Memory Alarm (Custom Metric from CloudWatch Agent)
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "${var.project_name}/${var.environment}"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold
  alarm_description   = "Memory utilization exceeds ${var.memory_alarm_threshold}%"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]
  ok_actions          = [aws_sns_topic.alarms[0].arn]

  tags = var.tags
}

# RDS High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-rds-high-cpu"
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
    DBInstanceIdentifier = "${var.project_name}-${var.environment}-db"
  }

  tags = var.tags
}

# RDS Low Storage Alarm
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_storage_alarm_threshold * 1024 * 1024 * 1024 # Convert GB to bytes
  alarm_description   = "RDS free storage below ${var.rds_storage_alarm_threshold}GB"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]
  ok_actions          = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    DBInstanceIdentifier = "${var.project_name}-${var.environment}-db"
  }

  tags = var.tags
}

# Error Log Alarm
resource "aws_cloudwatch_metric_alarm" "error_logs" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ErrorCount"
  namespace           = "${var.project_name}/${var.environment}"
  period              = 300
  statistic           = "Sum"
  threshold           = var.error_log_threshold
  alarm_description   = "Error count exceeds ${var.error_log_threshold} in 5 minutes"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  tags = var.tags
}

# -----------------------------------------------------------------------------
# CloudWatch Log Metric Filters
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "${var.project_name}-${var.environment}-errors"
  pattern        = "?ERROR ?Error ?error ?FATAL ?Fatal ?fatal"
  log_group_name = aws_cloudwatch_log_group.main.name

  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.project_name}/${var.environment}"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "warnings" {
  name           = "${var.project_name}-${var.environment}-warnings"
  pattern        = "?WARN ?Warning ?warning"
  log_group_name = aws_cloudwatch_log_group.main.name

  metric_transformation {
    name      = "WarningCount"
    namespace = "${var.project_name}/${var.environment}"
    value     = "1"
  }
}

# -----------------------------------------------------------------------------
# X-Ray
# -----------------------------------------------------------------------------

resource "aws_xray_sampling_rule" "main" {
  count = var.enable_xray ? 1 : 0

  rule_name      = "${var.project_name}-${var.environment}"
  priority       = 1000
  version        = 1
  reservoir_size = 5
  fixed_rate     = 0.05
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "${var.project_name}-${var.environment}"
  resource_arn   = "*"

  tags = var.tags
}

# Data Sources
data "aws_region" "current" {}
