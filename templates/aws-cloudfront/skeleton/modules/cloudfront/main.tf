# =============================================================================
# AWS CloudFront Module
# =============================================================================
# Reusable module for creating a CloudFront distribution with Origin Access
# Control, caching configuration, and optional custom domain support.
# =============================================================================

locals {
  distribution_name = "${var.org_prefix}-${var.name}-${var.environment}"
  s3_origin_id      = "${var.name}-s3-origin"
}

# -----------------------------------------------------------------------------
# Origin Access Control (OAC) for S3
# -----------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${local.distribution_name}-oac"
  description                       = "Origin Access Control for ${local.distribution_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -----------------------------------------------------------------------------
# CloudFront Distribution
# -----------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "this" {
  enabled             = var.enabled
  is_ipv6_enabled     = var.ipv6_enabled
  comment             = var.comment != "" ? var.comment : "CloudFront distribution for ${local.distribution_name}"
  default_root_object = var.default_root_object
  price_class         = var.price_class
  aliases             = var.custom_domain != "" ? [var.custom_domain] : []
  web_acl_id          = var.web_acl_id

  # S3 Origin Configuration
  origin {
    domain_name              = var.origin_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
    origin_path              = var.origin_path

    dynamic "custom_header" {
      for_each = var.origin_custom_headers
      content {
        name  = custom_header.value.name
        value = custom_header.value.value
      }
    }
  }

  # Default Cache Behavior
  default_cache_behavior {
    allowed_methods  = var.allowed_methods
    cached_methods   = var.cached_methods
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = var.forward_query_string
      headers      = var.forward_headers

      cookies {
        forward           = var.forward_cookies
        whitelisted_names = var.whitelisted_cookie_names
      }
    }

    viewer_protocol_policy = var.viewer_protocol_policy
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
    compress               = var.enable_compression

    dynamic "function_association" {
      for_each = var.function_associations
      content {
        event_type   = function_association.value.event_type
        function_arn = function_association.value.function_arn
      }
    }

    dynamic "lambda_function_association" {
      for_each = var.lambda_function_associations
      content {
        event_type   = lambda_function_association.value.event_type
        lambda_arn   = lambda_function_association.value.lambda_arn
        include_body = lookup(lambda_function_association.value, "include_body", false)
      }
    }
  }

  # Custom Error Responses
  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = lookup(custom_error_response.value, "response_code", null)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", null)
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", null)
    }
  }

  # Geo Restrictions
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  # SSL Certificate Configuration
  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == "" ? true : false
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.acm_certificate_arn != "" ? var.ssl_support_method : null
    minimum_protocol_version       = var.acm_certificate_arn != "" ? var.minimum_protocol_version : null
  }

  # Logging Configuration
  dynamic "logging_config" {
    for_each = var.logging_enabled ? [1] : []
    content {
      bucket          = var.logging_bucket
      prefix          = var.logging_prefix != "" ? var.logging_prefix : "${var.name}/"
      include_cookies = var.logging_include_cookies
    }
  }

  tags = merge(var.tags, {
    Name = local.distribution_name
  })

  # Wait for distribution to be deployed
  wait_for_deployment = var.wait_for_deployment
}
