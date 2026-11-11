# -----------------------------------------------------------------------------
# Virtual machine: EC2 instance in a private subnet, reached with Session
# Manager, stopped on a schedule outside production
# -----------------------------------------------------------------------------

variable "vm_instance_type" {
  description = "EC2 instance type of the virtual machine."
  type        = string
  default     = "t3.micro"
}

variable "auto_shutdown_schedule" {
  description = "Cron expression (minute hour * * weekdays, UTC) at which the virtual machine is stopped outside production. Null disables it."
  type        = string
  default     = null

  validation {
    condition     = var.auto_shutdown_schedule == null || can(regex("^[0-5]?[0-9] ([01]?[0-9]|2[0-3]) \\* \\* (\\*|[0-6](-[0-6])?(,[0-6](-[0-6])?)*)$", var.auto_shutdown_schedule))
    error_message = "auto_shutdown_schedule must be a cron expression of the form \"minute hour * * weekdays\", for example \"0 19 * * 1-5\"."
  }
}

locals {
  # EventBridge Scheduler uses names for weekdays and its own field order, so
  # "0 19 * * 1-5" becomes "cron(0 19 ? * MON-FRI *)".
  shutdown_fields   = var.auto_shutdown_schedule == null ? [] : split(" ", var.auto_shutdown_schedule)
  weekday_names     = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
  shutdown_weekdays = length(local.shutdown_fields) == 0 ? "" : join("", [for token in regexall("[0-6]|[-,*]", local.shutdown_fields[4]) : can(tonumber(token)) ? local.weekday_names[tonumber(token)] : token])
  shutdown_cron = length(local.shutdown_fields) == 0 ? null : (
    local.shutdown_weekdays == "*"
    ? "cron(${local.shutdown_fields[0]} ${local.shutdown_fields[1]} * * ? *)"
    : "cron(${local.shutdown_fields[0]} ${local.shutdown_fields[1]} ? * ${local.shutdown_weekdays} *)"
  )

  vm_auto_shutdown_enabled = var.environment != "production" && var.auto_shutdown_schedule != null
}

data "aws_ami" "amazon_linux" {
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

resource "aws_iam_role" "vm" {
  name = module.naming.standard["vm"]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Session Manager access, so the machine needs no SSH key and no open port.
resource "aws_iam_role_policy_attachment" "vm_ssm" {
  role       = aws_iam_role.vm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "vm" {
  name = module.naming.standard["vm"]
  role = aws_iam_role.vm.name
}

resource "aws_security_group" "vm" {
  name        = module.naming.standard["vm"]
  description = "Virtual machine of the ${var.component_name} component"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = module.naming.standard["vm"]
  }
}

# Session Manager and the package repositories are reached over HTTPS at
# addresses that change, so the destination cannot be narrowed to a CIDR list.
# trivy:ignore:AVD-AWS-0104
resource "aws_vpc_security_group_egress_rule" "vm_https" {
  security_group_id = aws_security_group.vm.id
  description       = "HTTPS for Session Manager and package updates"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.vm_instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.vm.id]
  iam_instance_profile   = aws_iam_instance_profile.vm.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  tags = {
    Name = module.naming.standard["vm"]
  }

  # A newer AMI must not replace a running machine on the next apply.
  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_iam_role" "vm_shutdown" {
  count = local.vm_auto_shutdown_enabled ? 1 : 0

  name = module.naming.standard["vmstop"]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "scheduler.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "vm_shutdown" {
  count = local.vm_auto_shutdown_enabled ? 1 : 0

  name = "stop-instance"
  role = aws_iam_role.vm_shutdown[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ec2:StopInstances"
      Resource = aws_instance.this.arn
    }]
  })
}

resource "aws_scheduler_schedule" "vm_shutdown" {
  count = local.vm_auto_shutdown_enabled ? 1 : 0

  name                         = module.naming.standard["vmstop"]
  description                  = "Stops the ${var.component_name} virtual machine"
  schedule_expression          = local.shutdown_cron
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.vm_shutdown[0].arn
    input    = jsonencode({ InstanceIds = [aws_instance.this.id] })
  }
}

output "vm_instance_id" {
  description = "Instance ID of the virtual machine, for `aws ssm start-session --target`."
  value       = aws_instance.this.id
}

output "vm_private_ip" {
  description = "Private IP address of the virtual machine."
  value       = aws_instance.this.private_ip
}
