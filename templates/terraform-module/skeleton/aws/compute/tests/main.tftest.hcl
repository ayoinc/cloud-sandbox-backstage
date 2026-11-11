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
  vpc_id       = "vpc-0123456789abcdef0"
  subnet_ids   = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
}

run "defaults" {
  command = plan

  assert {
    condition     = aws_autoscaling_group.main.name == "my-project-dev-asg"
    error_message = "The Auto Scaling group name must be derived from the name prefix."
  }

  assert {
    condition     = aws_autoscaling_group.main.min_size == 1 && aws_autoscaling_group.main.max_size == 3 && aws_autoscaling_group.main.desired_capacity == 2
    error_message = "Default capacity must be 1/2/3."
  }

  assert {
    condition     = aws_autoscaling_group.main.health_check_type == "EC2" && length(aws_autoscaling_group.main.vpc_zone_identifier) == 2
    error_message = "The group must use EC2 health checks and the given subnets."
  }

  assert {
    condition     = aws_launch_template.main.instance_type == "t3.micro" && length(data.aws_ami.amazon_linux) == 1
    error_message = "The default instance type and the Amazon Linux 2023 AMI lookup are expected."
  }

  assert {
    condition     = aws_launch_template.main.metadata_options[0].http_tokens == "required" && aws_launch_template.main.metadata_options[0].http_put_response_hop_limit == 1
    error_message = "IMDSv2 must be required with a hop limit of 1."
  }

  assert {
    condition     = aws_launch_template.main.block_device_mappings[0].ebs[0].encrypted == "true" && aws_launch_template.main.block_device_mappings[0].ebs[0].volume_size == 20
    error_message = "The root volume must be encrypted and 20 GB by default."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.ssh) == 0 && length(aws_vpc_security_group_ingress_rule.app_cidr) == 0 && length(aws_vpc_security_group_ingress_rule.app_security_group) == 0
    error_message = "No ingress may be open by default."
  }

  assert {
    condition     = aws_vpc_security_group_egress_rule.vpc.cidr_ipv4 == "10.0.0.0/16" && aws_vpc_security_group_egress_rule.https.to_port == 443
    error_message = "Egress must be limited to the VPC and outbound HTTPS."
  }

  assert {
    condition     = aws_iam_role_policy_attachment.ssm.policy_arn == "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    error_message = "Session Manager access must be attached."
  }

  assert {
    condition     = aws_cloudwatch_log_group.cloud_init.name == "/my-project/dev/compute/cloud-init" && aws_cloudwatch_log_group.audit.retention_in_days == 30
    error_message = "Instance log groups must be created with the default retention."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.scale_up.threshold == 80 && aws_cloudwatch_metric_alarm.scale_down.threshold == 20
    error_message = "Default scaling thresholds must be 80 and 20."
  }
}

run "custom_ami_and_access" {
  command = plan

  variables {
    ami_id                         = "ami-0123456789abcdef0"
    instance_type                  = "t3.small"
    root_volume_size               = 50
    ssh_allowed_cidrs              = ["10.0.0.0/16"]
    app_ports                      = [8080, 8443]
    app_allowed_cidrs              = ["10.0.0.0/16", "10.1.0.0/16"]
    app_allowed_security_group_ids = ["sg-0123456789abcdef0"]
    enable_detailed_monitoring     = false
  }

  assert {
    condition     = aws_launch_template.main.image_id == "ami-0123456789abcdef0" && length(data.aws_ami.amazon_linux) == 0
    error_message = "A supplied AMI must be used without looking up Amazon Linux."
  }

  assert {
    condition     = aws_launch_template.main.instance_type == "t3.small" && aws_launch_template.main.block_device_mappings[0].ebs[0].volume_size == 50
    error_message = "Instance type and volume size must be applied."
  }

  assert {
    condition     = aws_launch_template.main.monitoring[0].enabled == false
    error_message = "Detailed monitoring must be switchable."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.ssh) == 1 && aws_vpc_security_group_ingress_rule.ssh[0].cidr_ipv4 == "10.0.0.0/16"
    error_message = "SSH must be allowed from the given CIDR only."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.app_cidr) == 4 && length(aws_vpc_security_group_ingress_rule.app_security_group) == 2
    error_message = "One rule per port and source is expected."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.app_security_group[1].from_port == 8443 && aws_vpc_security_group_ingress_rule.app_security_group[1].referenced_security_group_id == "sg-0123456789abcdef0"
    error_message = "Application ports must be opened to the given security group."
  }
}

run "load_balancer_and_scaling" {
  command = plan

  variables {
    target_group_arns    = ["arn:aws:elasticloadbalancing:eu-west-2:123456789012:targetgroup/app/0123456789abcdef"]
    health_check_type    = "ELB"
    min_size             = 2
    max_size             = 6
    desired_capacity     = 4
    scale_up_threshold   = 70
    scale_down_threshold = 30
    log_retention_days   = 90
  }

  assert {
    condition     = aws_autoscaling_group.main.health_check_type == "ELB" && length(aws_autoscaling_group.main.target_group_arns) == 1
    error_message = "ELB health checks and target groups must be applied."
  }

  assert {
    condition     = aws_autoscaling_group.main.min_size == 2 && aws_autoscaling_group.main.max_size == 6 && aws_autoscaling_group.main.desired_capacity == 4
    error_message = "Capacity settings must be applied."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.scale_up.threshold == 70 && aws_cloudwatch_metric_alarm.scale_down.threshold == 30
    error_message = "Scaling thresholds must be applied."
  }

  assert {
    condition     = aws_cloudwatch_log_group.cloud_init.retention_in_days == 90
    error_message = "Log retention must be applied."
  }
}

run "requires_vpc" {
  command = plan

  variables {
    vpc_id = null
  }

  expect_failures = [var.vpc_id]
}

run "requires_subnets" {
  command = plan

  variables {
    subnet_ids = []
  }

  expect_failures = [var.subnet_ids]
}

run "elb_health_check_requires_target_group" {
  command = plan

  variables {
    health_check_type = "ELB"
  }

  expect_failures = [aws_autoscaling_group.main]
}

run "rejects_public_app_ingress" {
  command = plan

  variables {
    app_allowed_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.app_allowed_cidrs]
}

run "rejects_inconsistent_capacity" {
  command = plan

  variables {
    desired_capacity = 5
  }

  expect_failures = [var.desired_capacity]
}
