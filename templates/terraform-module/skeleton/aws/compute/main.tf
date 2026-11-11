# -----------------------------------------------------------------------------
# AWS Compute Module - Main Resources
# -----------------------------------------------------------------------------

data "aws_partition" "current" {}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Latest full (not minimal) Amazon Linux 2023 AMI, which ships the SSM agent.
data "aws_ami" "amazon_linux" {
  count = local.use_default_ami ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  # Lowercase, hyphen-separated and short enough for every AWS name limit.
  project     = trimsuffix(substr(replace(lower(var.project_name), "/[^a-z0-9]+/", "-"), 0, 23), "-")
  name_prefix = "${local.project}-${var.environment}"

  # Log groups and custom metrics of the project live under this path.
  path_prefix = "${local.project}/${var.environment}"

  use_default_ami = var.ami_id == null || var.ami_id == ""

  managed_policy_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"

  app_cidr_rules = [for pair in setproduct(var.app_ports, var.app_allowed_cidrs) : {
    port = pair[0]
    cidr = pair[1]
  }]
  app_security_group_rules = [for pair in setproduct(var.app_ports, var.app_allowed_security_group_ids) : {
    port              = pair[0]
    security_group_id = pair[1]
  }]

  # Ships boot and audit logs and publishes memory/disk metrics aggregated per
  # Auto Scaling group, in the namespace the observability module alarms on.
  cloudwatch_agent_config = jsonencode({
    agent = {
      metrics_collection_interval = 60
    }
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path       = "/var/log/cloud-init-output.log"
              log_group_name  = aws_cloudwatch_log_group.cloud_init.name
              log_stream_name = "{instance_id}"
            },
            {
              file_path       = "/var/log/audit/audit.log"
              log_group_name  = aws_cloudwatch_log_group.audit.name
              log_stream_name = "{instance_id}"
            }
          ]
        }
      }
    }
    metrics = {
      namespace = local.path_prefix
      append_dimensions = {
        AutoScalingGroupName = "$${aws:AutoScalingGroupName}"
      }
      aggregation_dimensions = [["AutoScalingGroupName"]]
      metrics_collected = {
        cpu = {
          measurement = ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"]
          totalcpu    = true
        }
        disk = {
          measurement = ["used_percent"]
          resources   = ["/"]
        }
        mem = {
          measurement = ["mem_used_percent"]
        }
      }
    }
  })
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "compute" {
  name_prefix = "${local.name_prefix}-compute-"
  description = "Security group for compute instances"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-compute-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  count = length(var.ssh_allowed_cidrs)

  security_group_id = aws_security_group.compute.id
  description       = "SSH from an allowed network"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.ssh_allowed_cidrs[count.index]

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "app_cidr" {
  count = length(local.app_cidr_rules)

  security_group_id = aws_security_group.compute.id
  description       = "Application port from an allowed network"
  ip_protocol       = "tcp"
  from_port         = local.app_cidr_rules[count.index].port
  to_port           = local.app_cidr_rules[count.index].port
  cidr_ipv4         = local.app_cidr_rules[count.index].cidr

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "app_security_group" {
  count = length(local.app_security_group_rules)

  security_group_id            = aws_security_group.compute.id
  description                  = "Application port from an allowed security group"
  ip_protocol                  = "tcp"
  from_port                    = local.app_security_group_rules[count.index].port
  to_port                      = local.app_security_group_rules[count.index].port
  referenced_security_group_id = local.app_security_group_rules[count.index].security_group_id

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "vpc" {
  security_group_id = aws_security_group.compute.id
  description       = "Any traffic to destinations inside the VPC"
  ip_protocol       = "-1"
  cidr_ipv4         = data.aws_vpc.selected.cidr_block

  tags = var.tags
}

# Instances reach package repositories and the SSM, CloudWatch and other AWS
# APIs over HTTPS; these endpoints have no fixed address range.
# trivy:ignore:AVD-AWS-0104
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.compute.id
  description       = "HTTPS to package repositories and AWS APIs"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"

  tags = var.tags
}

# -----------------------------------------------------------------------------
# IAM
# -----------------------------------------------------------------------------

resource "aws_iam_role" "compute" {
  name = "${local.name_prefix}-compute-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# Session Manager access
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.compute.name
  policy_arn = "${local.managed_policy_prefix}/AmazonSSMManagedInstanceCore"
}

# CloudWatch agent: logs and custom metrics
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.compute.name
  policy_arn = "${local.managed_policy_prefix}/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "compute" {
  name = "${local.name_prefix}-compute-profile"
  role = aws_iam_role.compute.name

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Instance log groups
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "cloud_init" {
  name              = "/${local.path_prefix}/compute/cloud-init"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "audit" {
  name              = "/${local.path_prefix}/compute/audit"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Launch Template and Auto Scaling Group
# -----------------------------------------------------------------------------

resource "aws_launch_template" "main" {
  name_prefix   = "${local.name_prefix}-"
  image_id      = local.use_default_ami ? data.aws_ami.amazon_linux[0].id : var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.compute.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.compute.arn
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    name_prefix             = local.name_prefix
    cloudwatch_agent_config = local.cloudwatch_agent_config
  }))

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # IMDSv2 only; a hop limit of 1 keeps containers away from instance credentials.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${local.name_prefix}-instance"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name = "${local.name_prefix}-volume"
    })
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main" {
  name                = "${local.name_prefix}-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns
  health_check_type   = var.health_check_type

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_grace_period = var.health_check_grace_period

  # A new launch template version starts a rolling instance refresh.
  launch_template {
    id      = aws_launch_template.main.id
    version = aws_launch_template.main.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  dynamic "tag" {
    for_each = merge(var.tags, {
      Name = "${local.name_prefix}-asg"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]

    precondition {
      condition     = var.health_check_type == "EC2" || length(var.target_group_arns) > 0
      error_message = "health_check_type ELB requires at least one entry in target_group_arns."
    }
  }

  # Instances need their role permissions and log groups when they boot.
  depends_on = [
    aws_iam_role_policy_attachment.ssm,
    aws_iam_role_policy_attachment.cloudwatch,
    aws_cloudwatch_log_group.cloud_init,
    aws_cloudwatch_log_group.audit,
  ]
}

# -----------------------------------------------------------------------------
# CPU based scaling
# -----------------------------------------------------------------------------

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${local.name_prefix}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${local.name_prefix}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_name          = "${local.name_prefix}-asg-scale-up"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.scale_up_threshold
  alarm_description   = "Add an instance when average CPU is above ${var.scale_up_threshold}%"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_name          = "${local.name_prefix}-asg-scale-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.scale_down_threshold
  alarm_description   = "Remove an instance when average CPU is below ${var.scale_down_threshold}%"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = var.tags
}
