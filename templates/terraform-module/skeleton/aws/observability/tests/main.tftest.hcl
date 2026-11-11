mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "eu-west-2"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }

  mock_data "aws_vpc" {
    defaults = {
      cidr_block = "10.0.0.0/16"
    }
  }
}

variables {
  project_name = "My_Project"
  environment  = "dev"
}

run "defaults" {
  command = plan

  assert {
    condition     = aws_cloudwatch_log_group.main.name == "/my-project/dev/application" && aws_cloudwatch_log_group.main.retention_in_days == 30
    error_message = "The application log group name or retention is wrong."
  }

  assert {
    condition     = aws_cloudwatch_log_group.security.name == "/my-project/dev/security" && aws_cloudwatch_log_group.security.retention_in_days == 365
    error_message = "Security logs must be kept for a year by default."
  }

  assert {
    condition     = aws_cloudwatch_dashboard.main[0].dashboard_name == "my-project-dev"
    error_message = "The dashboard must be created by default."
  }

  assert {
    condition     = strcontains(aws_cloudwatch_dashboard.main[0].dashboard_body, "my-project-dev-asg") && strcontains(aws_cloudwatch_dashboard.main[0].dashboard_body, "my-project-dev-db") && strcontains(aws_cloudwatch_dashboard.main[0].dashboard_body, "eu-west-2")
    error_message = "The dashboard must chart the conventional Auto Scaling group and database in the current region."
  }

  assert {
    condition     = aws_sns_topic.alarms[0].name == "my-project-dev-alarms" && length(aws_sns_topic_subscription.email) == 0
    error_message = "The alarm topic is created without a subscription by default."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.high_cpu[0].threshold == 80 && aws_cloudwatch_metric_alarm.high_cpu[0].dimensions["AutoScalingGroupName"] == "my-project-dev-asg"
    error_message = "The CPU alarm must watch the conventional Auto Scaling group at 80%."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.high_memory[0].namespace == "my-project/dev" && aws_cloudwatch_metric_alarm.high_memory[0].dimensions["AutoScalingGroupName"] == "my-project-dev-asg"
    error_message = "The memory alarm must watch the CloudWatch agent metric of the Auto Scaling group."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_low_storage[0].threshold == 10737418240 && aws_cloudwatch_metric_alarm.rds_low_storage[0].dimensions["DBInstanceIdentifier"] == "my-project-dev-db"
    error_message = "The storage alarm must fire below 10 GB on the conventional database."
  }

  assert {
    condition     = aws_cloudwatch_log_metric_filter.errors.metric_transformation[0].namespace == "my-project/dev" && aws_cloudwatch_metric_alarm.error_logs[0].metric_name == "ErrorCount"
    error_message = "The error alarm must read the metric produced by the log metric filter."
  }

  assert {
    condition     = aws_xray_sampling_rule.main[0].rule_name == "my-project-dev" && aws_xray_sampling_rule.main[0].fixed_rate == 0.05
    error_message = "The X-Ray sampling rule must be created by default."
  }
}

run "encrypted_with_notifications" {
  command = plan

  variables {
    kms_key_arn                 = "arn:aws:kms:eu-west-2:123456789012:key/11111111-2222-3333-4444-555555555555"
    alarm_email                 = "alerts@example.com"
    autoscaling_group_name      = "web-asg"
    db_instance_identifier      = "orders-db"
    log_retention_days          = 90
    cpu_alarm_threshold         = 70
    rds_storage_alarm_threshold = 20
  }

  assert {
    condition     = aws_cloudwatch_log_group.main.kms_key_id == var.kms_key_arn && aws_sns_topic.alarms[0].kms_master_key_id == var.kms_key_arn
    error_message = "Log groups and the alarm topic must use the supplied key."
  }

  assert {
    condition     = aws_sns_topic_subscription.email[0].endpoint == "alerts@example.com" && aws_sns_topic_subscription.email[0].protocol == "email"
    error_message = "The email subscription must be created."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.high_cpu[0].dimensions["AutoScalingGroupName"] == "web-asg" && aws_cloudwatch_metric_alarm.rds_high_cpu[0].dimensions["DBInstanceIdentifier"] == "orders-db"
    error_message = "Alarms must watch the given resources."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.high_cpu[0].threshold == 70 && aws_cloudwatch_metric_alarm.rds_low_storage[0].threshold == 21474836480
    error_message = "Alarm thresholds must be applied."
  }

  assert {
    condition     = aws_cloudwatch_log_group.system.retention_in_days == 90
    error_message = "Log retention must be applied."
  }
}

run "everything_optional_disabled" {
  command = plan

  variables {
    enable_dashboard = false
    enable_alarms    = false
    enable_xray      = false
    alarm_email      = "alerts@example.com"
  }

  assert {
    condition     = length(aws_cloudwatch_dashboard.main) == 0 && length(aws_xray_sampling_rule.main) == 0
    error_message = "Dashboard and X-Ray rule must be removable."
  }

  assert {
    condition     = length(aws_sns_topic.alarms) == 0 && length(aws_sns_topic_subscription.email) == 0 && length(aws_cloudwatch_metric_alarm.high_cpu) == 0 && length(aws_cloudwatch_metric_alarm.error_logs) == 0
    error_message = "Disabling alarms must remove the topic, subscription and alarms."
  }

  assert {
    condition     = output.dashboard_name == null && output.sns_topic_arn == null && length(output.alarm_arns) == 0 && output.xray_sampling_rule_arn == null
    error_message = "Outputs of disabled features must be empty."
  }

  assert {
    condition     = aws_cloudwatch_log_metric_filter.warnings.metric_transformation[0].name == "WarningCount"
    error_message = "Log groups and metric filters are always created."
  }
}

run "rejects_invalid_retention" {
  command = plan

  variables {
    log_retention_days = 45
  }

  expect_failures = [var.log_retention_days]
}
