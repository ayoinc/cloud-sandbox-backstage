data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "${var.project_name}-${var.environment}"

  tags = {
    project       = var.project_name
    environment   = var.environment
    business-unit = var.business_unit
    managed-by    = "terraform"
  }

  zones        = slice(data.aws_availability_zones.available.names, 0, 2)
  max_replicas = var.enable_autoscaling ? var.max_replicas : var.min_replicas
  production   = var.environment == "prod"
}

# ---------------------------------------------------------------------------
# Network: public subnets for the load balancer and the containers, private
# subnets without a route to the internet for the database and the cache.
# ---------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = local.name }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = local.zones[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${local.name}-public-${count.index + 1}" }
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)
  availability_zone = local.zones[count.index]

  tags = { Name = "${local.name}-private-${count.index + 1}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "load_balancer" {
  name_prefix = "${local.name}-lb-"
  description = "Load balancer of the store"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer_http" {
  security_group_id = aws_security_group.load_balancer.id
  description       = "HTTP from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "load_balancer_all" {
  security_group_id = aws_security_group.load_balancer.id
  description       = "To the containers"
  cidr_ipv4         = aws_vpc.main.cidr_block
  ip_protocol       = "-1"
}

resource "aws_security_group" "services" {
  name_prefix = "${local.name}-services-"
  description = "Containers of the store"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "services_from_load_balancer" {
  security_group_id            = aws_security_group.services.id
  description                  = "From the load balancer"
  referenced_security_group_id = aws_security_group.load_balancer.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

resource "aws_vpc_security_group_egress_rule" "services_all" {
  security_group_id = aws_security_group.services.id
  description       = "Image registry, database and cache"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "data" {
  name_prefix = "${local.name}-data-"
  description = "Database and cache of the store"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "data_postgres" {
  security_group_id            = aws_security_group.data.id
  description                  = "PostgreSQL from the containers"
  referenced_security_group_id = aws_security_group.services.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

resource "aws_vpc_security_group_ingress_rule" "data_redis" {
  security_group_id            = aws_security_group.data.id
  description                  = "Redis from the containers"
  referenced_security_group_id = aws_security_group.services.id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

resource "random_password" "database" {
  length  = 32
  special = false
}

resource "aws_db_subnet_group" "main" {
  name       = local.name
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "main" {
  identifier     = local.name
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.database_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  db_name  = "store"
  username = "store"
  password = random_password.database.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.data.id]

  multi_az                  = local.production
  backup_retention_period   = local.production ? 30 : 7
  deletion_protection       = local.production
  skip_final_snapshot       = !local.production
  final_snapshot_identifier = local.production ? "${local.name}-final" : null
}

# ---------------------------------------------------------------------------
# Cache
# ---------------------------------------------------------------------------

resource "aws_elasticache_subnet_group" "main" {
  count = var.enable_cache ? 1 : 0

  name       = local.name
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_elasticache_replication_group" "main" {
  count = var.enable_cache ? 1 : 0

  replication_group_id = local.name
  description          = "Catalogue cache of ${local.name}"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_clusters   = local.production ? 2 : 1

  automatic_failover_enabled = local.production
  at_rest_encryption_enabled = true
  subnet_group_name          = aws_elasticache_subnet_group.main[0].name
  security_group_ids         = [aws_security_group.data.id]
}

# ---------------------------------------------------------------------------
# Secrets of the API, read by ECS when a container starts
# ---------------------------------------------------------------------------

resource "random_password" "admin_token" {
  length  = 40
  special = false
}

# RDS requires TLS. Its certificates are signed by the Amazon RDS certificate
# authority, which Node.js does not know: the connection is encrypted but the
# certificate is not checked. Add the RDS CA bundle to the image and switch to
# sslmode=verify-full to check it.
resource "aws_ssm_parameter" "database_url" {
  name  = "/${local.name}/database-url"
  type  = "SecureString"
  value = "postgres://store:${random_password.database.result}@${aws_db_instance.main.address}:5432/store?sslmode=no-verify"
}

resource "aws_ssm_parameter" "admin_token" {
  name  = "/${local.name}/admin-token"
  type  = "SecureString"
  value = random_password.admin_token.result
}

# ---------------------------------------------------------------------------
# Load balancer: /api/* goes to the API, everything else to the storefront
# ---------------------------------------------------------------------------

resource "aws_lb" "main" {
  name_prefix        = "store-"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "backend" {
  name_prefix = "api-"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  protocol    = "HTTP"
  port        = 8080

  health_check {
    path = "/readyz"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "frontend" {
  name_prefix = "web-"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  protocol    = "HTTP"
  port        = 8080

  health_check {
    path = "/"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Plain HTTP: with the content delivery network on, visitors use HTTPS on its
# address. For your own domain, add an ACM certificate and an HTTPS listener.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# ---------------------------------------------------------------------------
# Containers on ECS Fargate
# ---------------------------------------------------------------------------

resource "aws_ecs_cluster" "main" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${local.name}"
  retention_in_days = 30
}

data "aws_iam_policy_document" "assume_by_ecs_tasks" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name_prefix        = "${local.name}-ecs-"
  assume_role_policy = data.aws_iam_policy_document.assume_by_ecs_tasks.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "read_secrets" {
  statement {
    actions   = ["ssm:GetParameters"]
    resources = [aws_ssm_parameter.database_url.arn, aws_ssm_parameter.admin_token.arn]
  }
}

resource "aws_iam_role_policy" "read_secrets" {
  name   = "read-secrets"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.read_secrets.json
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${local.name}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn

  container_definitions = jsonencode([{
    name         = "backend"
    image        = var.backend_image
    essential    = true
    portMappings = [{ containerPort = 8080, protocol = "tcp" }]

    environment = var.enable_cache ? [{
      name  = "REDIS_URL"
      value = "redis://${aws_elasticache_replication_group.main[0].primary_endpoint_address}:6379"
    }] : []

    secrets = [
      { name = "DATABASE_URL", valueFrom = aws_ssm_parameter.database_url.arn },
      { name = "ADMIN_TOKEN", valueFrom = aws_ssm_parameter.admin_token.arn },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.main.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "backend"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${local.name}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn

  container_definitions = jsonencode([{
    name         = "frontend"
    image        = var.frontend_image
    essential    = true
    portMappings = [{ containerPort = 8080, protocol = "tcp" }]

    # The load balancer already sends /api/* to the API; the storefront's own
    # proxy needs an address all the same.
    environment = [{ name = "BACKEND_URL", value = "http://${aws_lb.main.dns_name}" }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.main.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "frontend"
      }
    }
  }])
}

locals {
  services = {
    backend = {
      task_definition  = aws_ecs_task_definition.backend.arn
      target_group_arn = aws_lb_target_group.backend.arn
    }
    frontend = {
      task_definition  = aws_ecs_task_definition.frontend.arn
      target_group_arn = aws_lb_target_group.frontend.arn
    }
  }
}

resource "aws_ecs_service" "main" {
  for_each = local.services

  name            = each.key
  cluster         = aws_ecs_cluster.main.id
  task_definition = each.value.task_definition
  launch_type     = "FARGATE"
  desired_count   = var.min_replicas

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.services.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = each.value.target_group_arn
    container_name   = each.key
    container_port   = 8080
  }

  lifecycle {
    # Autoscaling changes the number of tasks; Terraform must not reset it.
    ignore_changes = [desired_count]
  }

  depends_on = [aws_lb_listener.http, aws_lb_listener_rule.api]
}

# ---------------------------------------------------------------------------
# Autoscaling: keep the average CPU use of each service at 60 %
# ---------------------------------------------------------------------------

resource "aws_appautoscaling_target" "main" {
  for_each = var.enable_autoscaling ? local.services : {}

  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main[each.key].name}"
  min_capacity       = var.min_replicas
  max_capacity       = local.max_replicas
}

resource "aws_appautoscaling_policy" "cpu" {
  for_each = aws_appautoscaling_target.main

  name               = "${local.name}-${each.key}-cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = each.value.service_namespace
  scalable_dimension = each.value.scalable_dimension
  resource_id        = each.value.resource_id

  target_tracking_scaling_policy_configuration {
    target_value = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

# ---------------------------------------------------------------------------
# Content delivery network
# ---------------------------------------------------------------------------

# Caches what the origin's Cache-Control headers allow: hashed assets for a
# year, pages and API answers not at all.
data "aws_cloudfront_cache_policy" "origin_headers" {
  name = "UseOriginCacheControlHeaders"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

resource "aws_cloudfront_distribution" "main" {
  count = var.enable_cdn ? 1 : 0

  enabled     = true
  comment     = local.name
  price_class = "PriceClass_100"

  origin {
    origin_id   = "load-balancer"
    domain_name = aws_lb.main.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id         = "load-balancer"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
    cache_policy_id          = data.aws_cloudfront_cache_policy.origin_headers.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
