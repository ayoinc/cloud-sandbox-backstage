# =============================================================================
# AWS CloudFront Terraform Tests
# =============================================================================
# These tests validate the CloudFront distribution configuration using the
# module structure. Tests use root module outputs to validate behavior.
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Mock Providers - Prevent actual AWS API calls
# -----------------------------------------------------------------------------
mock_provider "aws" {
  alias = "mock"
}

# -----------------------------------------------------------------------------
# Test: Basic CloudFront Distribution Configuration
# -----------------------------------------------------------------------------
run "basic_distribution_configuration" {
  command = plan

  variables {
    name               = "test-cdn"
    environment        = "development"
    region             = "us-east-1"
    org_prefix         = "myorg"
    origin_domain_name = "test-bucket.s3.us-east-1.amazonaws.com"
    price_class        = "PriceClass_100"
    default_ttl        = 86400
  }

  # Verify distribution is created
  assert {
    condition     = output.distribution_id != ""
    error_message = "Distribution ID should not be empty"
  }

  # Verify domain name is set
  assert {
    condition     = output.domain_name != ""
    error_message = "Domain name should not be empty"
  }

  # Verify price class
  assert {
    condition     = output.price_class == "PriceClass_100"
    error_message = "Price class should be PriceClass_100"
  }
}

# -----------------------------------------------------------------------------
# Test: Distribution Enabled
# -----------------------------------------------------------------------------
run "distribution_enabled" {
  command = plan

  variables {
    name               = "enabled-cdn"
    environment        = "staging"
    region             = "us-east-1"
    org_prefix         = "myorg"
    origin_domain_name = "staging-bucket.s3.us-east-1.amazonaws.com"
    enabled            = true
  }

  assert {
    condition     = output.enabled == true
    error_message = "Distribution should be enabled when enabled is true"
  }
}

# -----------------------------------------------------------------------------
# Test: Compression Enabled
# -----------------------------------------------------------------------------
run "compression_enabled" {
  command = plan

  variables {
    name               = "compressed-cdn"
    environment        = "development"
    region             = "us-east-1"
    org_prefix         = "myorg"
    origin_domain_name = "test-bucket.s3.us-east-1.amazonaws.com"
    enable_compression = true
  }

  assert {
    condition     = output.compression_enabled == true
    error_message = "Compression should be enabled when enable_compression is true"
  }
}

run "compression_disabled" {
  command = plan

  variables {
    name               = "uncompressed-cdn"
    environment        = "development"
    region             = "us-east-1"
    org_prefix         = "myorg"
    origin_domain_name = "test-bucket.s3.us-east-1.amazonaws.com"
    enable_compression = false
  }

  assert {
    condition     = output.compression_enabled == false
    error_message = "Compression should be disabled when enable_compression is false"
  }
}

# -----------------------------------------------------------------------------
# Test: Viewer Protocol Policies
# -----------------------------------------------------------------------------
run "https_only_policy" {
  command = plan

  variables {
    name                   = "secure-cdn"
    environment            = "production"
    region                 = "us-east-1"
    org_prefix             = "myorg"
    origin_domain_name     = "prod-bucket.s3.us-east-1.amazonaws.com"
    viewer_protocol_policy = "https-only"
  }

  assert {
    condition     = output.viewer_protocol_policy == "https-only"
    error_message = "Viewer protocol policy should be https-only"
  }
}

run "redirect_to_https_policy" {
  command = plan

  variables {
    name                   = "redirect-cdn"
    environment            = "staging"
    region                 = "us-east-1"
    org_prefix             = "myorg"
    origin_domain_name     = "staging-bucket.s3.us-east-1.amazonaws.com"
    viewer_protocol_policy = "redirect-to-https"
  }

  assert {
    condition     = output.viewer_protocol_policy == "redirect-to-https"
    error_message = "Viewer protocol policy should be redirect-to-https"
  }
}

# -----------------------------------------------------------------------------
# Test: Price Classes
# -----------------------------------------------------------------------------
run "price_class_100" {
  command = plan

  variables {
    name               = "budget-cdn"
    environment        = "development"
    region             = "us-east-1"
    org_prefix         = "myorg"
    origin_domain_name = "test-bucket.s3.us-east-1.amazonaws.com"
    price_class        = "PriceClass_100"
  }

  assert {
    condition     = output.price_class == "PriceClass_100"
    error_message = "Price class should be PriceClass_100"
  }
}

run "price_class_200" {
  command = plan

  variables {
    name               = "standard-cdn"
    environment        = "staging"
    region             = "us-east-1"
    org_prefix         = "myorg"
    origin_domain_name = "staging-bucket.s3.us-east-1.amazonaws.com"
    price_class        = "PriceClass_200"
  }

  assert {
    condition     = output.price_class == "PriceClass_200"
    error_message = "Price class should be PriceClass_200"
  }
}

run "price_class_all" {
  command = plan

  variables {
    name               = "global-cdn"
    environment        = "production"
    region             = "us-east-1"
    org_prefix         = "myorg"
    origin_domain_name = "prod-bucket.s3.us-east-1.amazonaws.com"
    price_class        = "PriceClass_All"
  }

  assert {
    condition     = output.price_class == "PriceClass_All"
    error_message = "Price class should be PriceClass_All"
  }
}

# -----------------------------------------------------------------------------
# Test: Custom Domain Configuration
# -----------------------------------------------------------------------------
run "no_custom_domain" {
  command = plan

  variables {
    name               = "default-cdn"
    environment        = "development"
    region             = "us-east-1"
    org_prefix         = "myorg"
    origin_domain_name = "test-bucket.s3.us-east-1.amazonaws.com"
    custom_domain      = ""
  }

  assert {
    condition     = output.custom_domain == ""
    error_message = "Custom domain should be empty when not configured"
  }
}

run "with_custom_domain" {
  command = plan

  variables {
    name                = "custom-cdn"
    environment         = "production"
    region              = "us-east-1"
    org_prefix          = "myorg"
    origin_domain_name  = "prod-bucket.s3.us-east-1.amazonaws.com"
    custom_domain       = "cdn.example.com"
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }

  assert {
    condition     = output.custom_domain == "cdn.example.com"
    error_message = "Custom domain should be cdn.example.com"
  }
}

# -----------------------------------------------------------------------------
# Test: Environment Validation
# -----------------------------------------------------------------------------
run "valid_development_environment" {
  command = plan

  variables {
    name               = "dev-cdn"
    environment        = "development"
    region             = "us-east-1"
    org_prefix         = "myorg"
    origin_domain_name = "dev-bucket.s3.us-east-1.amazonaws.com"
  }

  assert {
    condition     = can(output.distribution_id)
    error_message = "Development environment should produce valid distribution_id"
  }
}

run "valid_staging_environment" {
  command = plan

  variables {
    name               = "staging-cdn"
    environment        = "staging"
    region             = "us-east-1"
    org_prefix         = "myorg"
    origin_domain_name = "staging-bucket.s3.us-east-1.amazonaws.com"
  }

  assert {
    condition     = can(output.distribution_id)
    error_message = "Staging environment should produce valid distribution_id"
  }
}

run "valid_production_environment" {
  command = plan

  variables {
    name               = "prod-cdn"
    environment        = "production"
    region             = "us-east-1"
    org_prefix         = "myorg"
    origin_domain_name = "prod-bucket.s3.us-east-1.amazonaws.com"
  }

  assert {
    condition     = can(output.distribution_id)
    error_message = "Production environment should produce valid distribution_id"
  }
}

# -----------------------------------------------------------------------------
# Test: Distribution Info Summary
# -----------------------------------------------------------------------------
run "distribution_info_summary" {
  command = plan

  variables {
    name               = "summary-cdn"
    environment        = "staging"
    region             = "us-east-1"
    org_prefix         = "testorg"
    origin_domain_name = "test-bucket.s3.us-east-1.amazonaws.com"
    price_class        = "PriceClass_100"
    enable_compression = true
  }

  # Verify distribution_info summary output contains expected fields
  assert {
    condition     = output.distribution_info.price_class == "PriceClass_100"
    error_message = "Distribution info should show correct price class"
  }

  assert {
    condition     = output.distribution_info.compression_enabled == true
    error_message = "Distribution info should show compression enabled"
  }
}

# -----------------------------------------------------------------------------
# Test: Production Best Practices
# -----------------------------------------------------------------------------
run "production_best_practices" {
  command = plan

  variables {
    name                   = "enterprise-cdn"
    environment            = "production"
    region                 = "us-east-1"
    org_prefix             = "enterprise"
    origin_domain_name     = "enterprise-bucket.s3.us-east-1.amazonaws.com"
    price_class            = "PriceClass_All"
    viewer_protocol_policy = "https-only"
    enable_compression     = true
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  # HTTPS only for production
  assert {
    condition     = output.viewer_protocol_policy == "https-only"
    error_message = "Production should use https-only"
  }

  # Compression enabled
  assert {
    condition     = output.compression_enabled == true
    error_message = "Production should have compression enabled"
  }

  # Full price class for global reach
  assert {
    condition     = output.price_class == "PriceClass_All"
    error_message = "Production should use PriceClass_All for global reach"
  }
}

# -----------------------------------------------------------------------------
# Test: Origin Access Control
# -----------------------------------------------------------------------------
run "origin_access_control_created" {
  command = plan

  variables {
    name               = "oac-test"
    environment        = "development"
    region             = "us-east-1"
    org_prefix         = "myorg"
    origin_domain_name = "test-bucket.s3.us-east-1.amazonaws.com"
  }

  assert {
    condition     = output.origin_access_control_id != ""
    error_message = "Origin Access Control ID should not be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: Different Regions for Origin
# -----------------------------------------------------------------------------
run "us_west_2_origin" {
  command = plan

  variables {
    name               = "west-cdn"
    environment        = "development"
    region             = "us-west-2"
    org_prefix         = "myorg"
    origin_domain_name = "west-bucket.s3.us-west-2.amazonaws.com"
  }

  assert {
    condition     = can(output.distribution_id)
    error_message = "Distribution should be creatable with us-west-2 origin"
  }
}

run "eu_west_1_origin" {
  command = plan

  variables {
    name               = "eu-cdn"
    environment        = "production"
    region             = "eu-west-1"
    org_prefix         = "myorg"
    origin_domain_name = "eu-bucket.s3.eu-west-1.amazonaws.com"
  }

  assert {
    condition     = can(output.distribution_id)
    error_message = "Distribution should be creatable with eu-west-1 origin"
  }
}
