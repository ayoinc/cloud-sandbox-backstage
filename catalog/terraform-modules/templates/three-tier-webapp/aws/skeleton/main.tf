locals {
  name_prefix   = "${var.project_name}-${var.environment}"
  is_production = var.environment == "production"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  runs_containers = contains(["ecs-fargate", "ecs-ec2"], var.compute_type)
  runs_instances  = contains(["ecs-ec2", "ec2-asg"], var.compute_type)

  max_capacity = max(var.min_capacity, var.max_capacity)
}

# -----------------------------------------------------------------------------
# Network: public subnets for the load balancer, private subnets for the
# application, isolated subnets for the database.
# -----------------------------------------------------------------------------

#trivy:ignore:AVD-AWS-0164 Public subnets hold only the load balancer and NAT gateways, which need public addresses.
module "vpc" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/network/vpc?ref=${{ values.moduleRef }}"

  name        = local.name_prefix
  environment = var.environment
  vpc_cidr    = var.vpc_cidr

  public_subnet_cidrs   = [for index in range(3) : cidrsubnet(var.vpc_cidr, 4, index)]
  private_subnet_cidrs  = [for index in range(3) : cidrsubnet(var.vpc_cidr, 4, index + 4)]
  database_subnet_cidrs = [for index in range(3) : cidrsubnet(var.vpc_cidr, 4, index + 8)]

  enable_nat_gateway = true
  single_nat_gateway = !local.is_production
}

# -----------------------------------------------------------------------------
# Web tier: application load balancer
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb"
  description = "Traffic from the internet to the load balancer"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from the internet, redirected to HTTPS by the listener"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward requests to the application"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
}

# Used until a certificate for a real domain is supplied in certificate_arn.
resource "tls_private_key" "self_signed" {
  count = var.certificate_arn == null ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "self_signed" {
  count = var.certificate_arn == null ? 1 : 0

  private_key_pem       = tls_private_key.self_signed[0].private_key_pem
  validity_period_hours = 8760
  early_renewal_hours   = 720

  subject {
    common_name  = "${local.name_prefix}.internal"
    organization = var.project_name
  }

  allowed_uses = ["key_encipherment", "digital_signature", "server_auth"]
}

resource "aws_acm_certificate" "self_signed" {
  count = var.certificate_arn == null ? 1 : 0

  private_key      = tls_private_key.self_signed[0].private_key_pem
  certificate_body = tls_self_signed_cert.self_signed[0].cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

#trivy:ignore:AVD-AWS-0053 The load balancer is the public entry point of the application.
#trivy:ignore:AVD-AWS-0052 The alb module has no input for drop_invalid_header_fields.
module "alb" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/network/alb?ref=${{ values.moduleRef }}"

  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnet_ids
  security_groups = [aws_security_group.alb.id]

  certificate_arn            = coalesce(var.certificate_arn, one(aws_acm_certificate.self_signed[*].arn))
  enable_deletion_protection = local.is_production

  target_group_port     = var.container_port
  target_group_protocol = "HTTP"
  target_type           = local.runs_containers ? "ip" : "instance"
  health_check_path     = var.health_check_path
}
