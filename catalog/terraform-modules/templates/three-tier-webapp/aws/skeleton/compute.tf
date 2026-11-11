# -----------------------------------------------------------------------------
# Application tier. compute_type selects how the application runs:
#   ecs-fargate  ECS service on Fargate
#   ecs-ec2      ECS service on container instances from an Auto Scaling group
#   ec2-asg      EC2 instances in an Auto Scaling group behind the load balancer
# -----------------------------------------------------------------------------

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app"
  description = "Application tier"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${local.name_prefix}-app"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Requests from the load balancer"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
}

#trivy:ignore:AVD-AWS-0104 The application pulls images and calls AWS APIs through the NAT gateway.
resource "aws_vpc_security_group_egress_rule" "app_outbound" {
  security_group_id = aws_security_group.app.id
  description       = "Outbound through the NAT gateway"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# --- ECS (ecs-fargate and ecs-ec2) -------------------------------------------

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  count = local.runs_containers ? 1 : 0

  name               = "${local.name_prefix}-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  count = local.runs_containers ? 1 : 0

  role       = aws_iam_role.task_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

module "ecs" {
  count  = local.runs_containers ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/compute/ecs?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  environment  = var.environment

  cluster_name = "${local.name_prefix}-cluster"
  task_family  = "${local.name_prefix}-app"
  service_name = "${local.name_prefix}-app"

  capacity_providers       = var.compute_type == "ecs-fargate" ? ["FARGATE", "FARGATE_SPOT"] : []
  requires_compatibilities = var.compute_type == "ecs-fargate" ? ["FARGATE"] : ["EC2"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  desired_count            = var.min_capacity
  execution_role_arn       = aws_iam_role.task_execution[0].arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DATABASE_HOST", value = module.rds.db_instance_address },
        { name = "DATABASE_PORT", value = tostring(module.rds.db_instance_port) },
        { name = "DATABASE_NAME", value = module.rds.db_instance_name }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${local.name_prefix}-cluster/${local.name_prefix}-app"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])

  subnets          = module.vpc.private_subnet_ids
  security_groups  = [aws_security_group.app.id]
  target_group_arn = module.alb.target_group_arn
  container_name   = "app"
  container_port   = var.container_port
}

resource "aws_appautoscaling_target" "ecs" {
  count = local.runs_containers ? 1 : 0

  service_namespace  = "ecs"
  resource_id        = "service/${module.ecs[0].cluster_name}/${module.ecs[0].service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_capacity
  max_capacity       = local.max_capacity
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  count = local.runs_containers ? 1 : 0

  name               = "${local.name_prefix}-cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value = var.cpu_target

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

# --- EC2 instances (ecs-ec2 and ec2-asg) -------------------------------------

data "aws_ssm_parameter" "ami" {
  count = local.runs_instances && var.ami_id == null ? 1 : 0

  name = var.compute_type == "ecs-ec2" ? "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id" : "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  count = local.runs_instances ? 1 : 0

  name               = "${local.name_prefix}-instance"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "instance_ssm" {
  count = local.runs_instances ? 1 : 0

  role       = aws_iam_role.instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "instance_ecs" {
  count = var.compute_type == "ecs-ec2" ? 1 : 0

  role       = aws_iam_role.instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "instance" {
  count = local.runs_instances ? 1 : 0

  name = "${local.name_prefix}-instance"
  role = aws_iam_role.instance[0].name
}

locals {
  # ecs-ec2: join the ECS cluster. ec2-asg: serve a placeholder page until the
  # application is baked into ami_id or installed by its own user data.
  user_data = var.compute_type == "ecs-ec2" ? join("\n", [
    "#!/bin/bash",
    "echo ECS_CLUSTER=${local.name_prefix}-cluster >> /etc/ecs/ecs.config",
    ]) : join("\n", [
    "#!/bin/bash",
    "dnf install -y nginx",
    "systemctl enable --now nginx",
  ])
}

module "instances" {
  count  = local.runs_instances ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/compute/asg?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  environment  = var.environment

  ami_id                   = coalesce(var.ami_id, one(data.aws_ssm_parameter.ami[*].value))
  instance_type            = var.instance_type
  iam_instance_profile_arn = aws_iam_instance_profile.instance[0].arn
  user_data_base64         = base64encode(local.user_data)

  vpc_zone_identifier = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.app.id]

  min_size         = var.min_capacity
  max_size         = local.max_capacity
  desired_capacity = var.min_capacity

  # Instances behind the load balancer directly are replaced when it reports them unhealthy.
  health_check_type = var.compute_type == "ec2-asg" ? "ELB" : "EC2"
  target_group_arns = var.compute_type == "ec2-asg" ? [module.alb.target_group_arn] : []
}

resource "aws_autoscaling_policy" "instances_cpu" {
  count = local.runs_instances ? 1 : 0

  name                   = "${local.name_prefix}-cpu"
  autoscaling_group_name = module.instances[0].autoscaling_group_name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    target_value = var.cpu_target

    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}
