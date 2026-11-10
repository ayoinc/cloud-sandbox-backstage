# -----------------------------------------------------------------------------
# Alarm topic and application log group
# -----------------------------------------------------------------------------
resource "aws_sns_topic" "alarms" {
  count = var.enable_monitoring ? 1 : 0

  name              = "${local.name}-alarms"
  kms_master_key_id = aws_kms_key.main.id
}

resource "aws_sns_topic_subscription" "alarm_email" {
  count = var.enable_monitoring && var.alarm_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_log_group" "application" {
  count = var.enable_monitoring ? 1 : 0

  name              = "/${var.project_name}/${var.environment}/application"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.main.arn
}

# -----------------------------------------------------------------------------
# Alarms for the categories that are enabled
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "compute_cpu" {
  count = var.enable_monitoring && var.enable_compute ? 1 : 0

  alarm_name          = "${local.name}-compute-cpu"
  alarm_description   = "Average CPU of the Auto Scaling group above 80% for 10 minutes"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  period              = 300
  evaluation_periods  = 2
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.compute[0].name
  }
}

resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  count = var.enable_monitoring && var.enable_database ? 1 : 0

  alarm_name          = "${local.name}-database-cpu"
  alarm_description   = "CPU of the database above 80% for 10 minutes"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  period              = 300
  evaluation_periods  = 2
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main[0].identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "database_storage" {
  count = var.enable_monitoring && var.enable_database ? 1 : 0

  alarm_name          = "${local.name}-database-storage"
  alarm_description   = "Less than 2 GB of free database storage"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Minimum"
  comparison_operator = "LessThanThreshold"
  threshold           = 2147483648
  period              = 300
  evaluation_periods  = 1
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main[0].identifier
  }
}

# -----------------------------------------------------------------------------
# Dashboard
# -----------------------------------------------------------------------------
locals {
  dashboard_widgets = concat(
    var.enable_compute ? [{
      type   = "metric"
      width  = 12
      height = 6
      properties = {
        title   = "Auto Scaling group CPU"
        region  = var.region
        stat    = "Average"
        period  = 300
        metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${local.name}-compute"]]
      }
    }] : [],
    var.enable_database ? [{
      type   = "metric"
      width  = 12
      height = 6
      properties = {
        title   = "Database CPU"
        region  = var.region
        stat    = "Average"
        period  = 300
        metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", local.name]]
      }
    }] : [],
    var.enable_containers ? [{
      type   = "metric"
      width  = 12
      height = 6
      properties = {
        title   = "EKS API server requests"
        region  = var.region
        stat    = "Sum"
        period  = 300
        metrics = [["AWS/EKS", "apiserver_request_total", "ClusterName", local.name]]
      }
    }] : [],
    [{
      type   = "text"
      width  = 12
      height = 3
      properties = {
        markdown = "# ${local.name}\nComponent **${var.component_name}**, owned by ${var.owner}."
      }
    }]
  )
}

resource "aws_cloudwatch_dashboard" "main" {
  count = var.enable_monitoring ? 1 : 0

  dashboard_name = local.name
  dashboard_body = jsonencode({ widgets = local.dashboard_widgets })
}
