terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  # Separate records into standard and alias types
  standard_records = {
    for idx, record in var.records :
    "${record.name}-${record.type}-${idx}" => record
    if record.alias == null
  }

  alias_records = {
    for idx, record in var.records :
    "${record.name}-${record.type}-${idx}" => record
    if record.alias != null
  }
}

#------------------------------------------------------------------------------
# Route53 Hosted Zone
#------------------------------------------------------------------------------
resource "aws_route53_zone" "this" {
  name          = var.domain_name
  comment       = "Hosted zone for ${var.domain_name} - ${var.environment}"
  force_destroy = false

  dynamic "vpc" {
    for_each = var.private_zone ? var.vpc_ids : []
    content {
      vpc_id = vpc.value
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${replace(var.domain_name, ".", "-")}"
    }
  )
}

#------------------------------------------------------------------------------
# Standard DNS Records (A, AAAA, CNAME, MX, TXT, etc.)
#------------------------------------------------------------------------------
resource "aws_route53_record" "standard" {
  for_each = local.standard_records

  zone_id = aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records

  # Weighted routing
  dynamic "weighted_routing_policy" {
    for_each = each.value.weighted_routing != null ? [each.value.weighted_routing] : []
    content {
      weight = weighted_routing_policy.value.weight
    }
  }

  # Latency routing
  dynamic "latency_routing_policy" {
    for_each = each.value.latency_routing != null ? [each.value.latency_routing] : []
    content {
      region = latency_routing_policy.value.region
    }
  }

  # Geolocation routing
  dynamic "geolocation_routing_policy" {
    for_each = each.value.geolocation_routing != null ? [each.value.geolocation_routing] : []
    content {
      continent   = geolocation_routing_policy.value.continent
      country     = geolocation_routing_policy.value.country
      subdivision = geolocation_routing_policy.value.subdivision
    }
  }

  # Set identifier required for weighted, latency, geolocation routing
  set_identifier = each.value.set_identifier

  # Health check
  health_check_id = each.value.health_check_id
}

#------------------------------------------------------------------------------
# Alias DNS Records (ALB, CloudFront, S3, etc.)
#------------------------------------------------------------------------------
resource "aws_route53_record" "alias" {
  for_each = local.alias_records

  zone_id = aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = each.value.alias.name
    zone_id                = each.value.alias.zone_id
    evaluate_target_health = each.value.alias.evaluate_target_health
  }

  # Weighted routing
  dynamic "weighted_routing_policy" {
    for_each = each.value.weighted_routing != null ? [each.value.weighted_routing] : []
    content {
      weight = weighted_routing_policy.value.weight
    }
  }

  # Latency routing
  dynamic "latency_routing_policy" {
    for_each = each.value.latency_routing != null ? [each.value.latency_routing] : []
    content {
      region = latency_routing_policy.value.region
    }
  }

  # Geolocation routing
  dynamic "geolocation_routing_policy" {
    for_each = each.value.geolocation_routing != null ? [each.value.geolocation_routing] : []
    content {
      continent   = geolocation_routing_policy.value.continent
      country     = geolocation_routing_policy.value.country
      subdivision = geolocation_routing_policy.value.subdivision
    }
  }

  # Set identifier required for weighted, latency, geolocation routing
  set_identifier = each.value.set_identifier

  # Health check
  health_check_id = each.value.health_check_id
}

#------------------------------------------------------------------------------
# Additional VPC Associations (for private zones)
#------------------------------------------------------------------------------
resource "aws_route53_zone_association" "secondary" {
  for_each = var.private_zone && length(var.vpc_ids) > 1 ? toset(slice(var.vpc_ids, 1, length(var.vpc_ids))) : toset([])

  zone_id = aws_route53_zone.this.zone_id
  vpc_id  = each.value
}
