# -----------------------------------------------------------------------------
# EC2 Auto Scaling group in the private subnets
# -----------------------------------------------------------------------------
data "aws_ssm_parameter" "al2023_ami" {
  count = var.enable_compute ? 1 : 0

  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "compute" {
  count = var.enable_compute ? 1 : 0

  name        = "${local.name}-compute"
  description = "Instances of the ${local.name} Auto Scaling group"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${local.name}-compute"
  }
}

resource "aws_vpc_security_group_egress_rule" "compute_vpc" {
  count = var.enable_compute ? 1 : 0

  security_group_id = aws_security_group.compute[0].id
  description       = "Any traffic inside the VPC"
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
}

# Instances reach AWS APIs (Systems Manager, package repositories) through the
# NAT gateway, over HTTPS only.
# trivy:ignore:AVD-AWS-0104
resource "aws_vpc_security_group_egress_rule" "compute_https" {
  count = var.enable_compute ? 1 : 0

  security_group_id = aws_security_group.compute[0].id
  description       = "HTTPS to AWS APIs and package repositories"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_iam_role" "compute" {
  count = var.enable_compute ? 1 : 0

  name = "${local.name}-compute"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Session Manager replaces SSH: no key pairs and no inbound ports.
resource "aws_iam_role_policy_attachment" "compute_ssm" {
  count = var.enable_compute ? 1 : 0

  role       = aws_iam_role.compute[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "compute" {
  count = var.enable_compute ? 1 : 0

  name = "${local.name}-compute"
  role = aws_iam_role.compute[0].name
}

resource "aws_launch_template" "compute" {
  count = var.enable_compute ? 1 : 0

  name_prefix   = "${local.name}-"
  image_id      = data.aws_ssm_parameter.al2023_ami[0].value
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.compute[0].id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.compute[0].arn
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.ebs_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "${local.name}-compute" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(local.tags, { Name = "${local.name}-compute" })
  }
}

resource "aws_autoscaling_group" "compute" {
  count = var.enable_compute ? 1 : 0

  name                = "${local.name}-compute"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  vpc_zone_identifier = local.private_subnet_ids
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.compute[0].id
    version = aws_launch_template.compute[0].latest_version
  }

  instance_refresh {
    strategy = "Rolling"
  }

  tag {
    key                 = "Name"
    value               = "${local.name}-compute"
    propagate_at_launch = false
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}
