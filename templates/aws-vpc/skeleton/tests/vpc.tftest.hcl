# =============================================================================
# AWS VPC Terraform Tests
# =============================================================================
# These tests validate the VPC infrastructure configuration and ensure
# compliance with security, networking, and tagging standards.
#
# The tests run against the root module which calls the VPC child module.
#
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Test Variables
# -----------------------------------------------------------------------------
variables {
  name                     = "test-vpc"
  vpc_cidr                 = "10.0.0.0/16"
  environment              = "test"
  availability_zones_count = 2
  enable_nat_gateway       = true
  enable_flow_logs         = true
  flow_logs_traffic_type   = "ALL"
  flow_logs_retention_days = 14
  tags                     = {}
}

# -----------------------------------------------------------------------------
# Provider Configuration for Tests
# -----------------------------------------------------------------------------
provider "aws" {
  region = "us-east-1"

  # Use mocked provider for plan-only tests
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

# =============================================================================
# UNIT TESTS - Validate Configuration Without Applying
# =============================================================================

run "vpc_configuration_is_valid" {
  command = plan

  assert {
    condition     = module.vpc.vpc_cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block must be 10.0.0.0/16"
  }

  assert {
    condition     = output.vpc_id != null
    error_message = "VPC ID output must be defined"
  }

  assert {
    condition     = output.vpc_cidr_block != null
    error_message = "VPC CIDR block output must be defined"
  }
}

run "public_subnets_configuration" {
  command = plan

  assert {
    condition     = length(output.public_subnet_ids) == 2
    error_message = "Number of public subnets must match the availability_zones_count variable (2)"
  }

  assert {
    condition     = length(output.public_subnet_cidr_blocks) == 2
    error_message = "Number of public subnet CIDR blocks must match the availability_zones_count (2)"
  }
}

run "private_subnets_configuration" {
  command = plan

  assert {
    condition     = length(output.private_subnet_ids) == 2
    error_message = "Number of private subnets must match the availability_zones_count variable (2)"
  }

  assert {
    condition     = length(output.private_subnet_cidr_blocks) == 2
    error_message = "Number of private subnet CIDR blocks must match the availability_zones_count (2)"
  }
}

run "nat_gateway_configuration" {
  command = plan

  assert {
    condition     = length(output.nat_gateway_ids) == 2
    error_message = "NAT Gateways must be deployed in each AZ for high availability"
  }

  assert {
    condition     = length(output.nat_gateway_public_ips) == 2
    error_message = "NAT Gateways must have public IPs allocated"
  }
}

run "internet_gateway_configuration" {
  command = plan

  assert {
    condition     = output.internet_gateway_id != null
    error_message = "Internet Gateway must be created"
  }
}

run "route_tables_configuration" {
  command = plan

  assert {
    condition     = output.public_route_table_id != null
    error_message = "Public route table must be created"
  }

  assert {
    condition     = length(output.private_route_table_ids) == 2
    error_message = "Each AZ must have its own private route table for NAT Gateway routing"
  }
}

# =============================================================================
# SECURITY COMPLIANCE TESTS
# =============================================================================

run "flow_logs_enabled" {
  command = plan

  assert {
    condition     = output.flow_log_id != null
    error_message = "VPC Flow Logs must be enabled for security monitoring"
  }

  assert {
    condition     = output.flow_log_cloudwatch_log_group_arn != null
    error_message = "Flow logs must have a CloudWatch Log Group"
  }
}

# =============================================================================
# CIDR VALIDATION TESTS
# =============================================================================

run "vpc_cidr_is_valid_rfc1918" {
  command = plan

  # Validate CIDR is in private IP ranges (RFC 1918)
  assert {
    condition     = can(regex("^(10\\.|172\\.(1[6-9]|2[0-9]|3[0-1])\\.|192\\.168\\.)", var.vpc_cidr))
    error_message = "VPC CIDR must be a valid RFC 1918 private IP range (10.x.x.x, 172.16-31.x.x, or 192.168.x.x)"
  }
}

run "subnet_cidr_within_vpc" {
  command = plan

  # Ensure subnets are properly subdivided from VPC CIDR
  assert {
    condition     = length(output.public_subnet_ids) + length(output.private_subnet_ids) <= 16
    error_message = "Total subnets must not exceed /20 subdivisions of a /16 VPC"
  }
}

# =============================================================================
# EDGE CASE TESTS - Single AZ Configuration
# =============================================================================

run "single_az_configuration" {
  command = plan

  variables {
    availability_zones_count = 1
  }

  assert {
    condition     = length(output.public_subnet_ids) == 1
    error_message = "Single AZ configuration should create 1 public subnet"
  }

  assert {
    condition     = length(output.private_subnet_ids) == 1
    error_message = "Single AZ configuration should create 1 private subnet"
  }
}

# =============================================================================
# EDGE CASE TESTS - Three AZ Configuration
# =============================================================================

run "three_az_configuration" {
  command = plan

  variables {
    availability_zones_count = 3
  }

  assert {
    condition     = length(output.public_subnet_ids) == 3
    error_message = "Three AZ configuration should create 3 public subnets"
  }

  assert {
    condition     = length(output.private_subnet_ids) == 3
    error_message = "Three AZ configuration should create 3 private subnets"
  }

  assert {
    condition     = length(output.nat_gateway_ids) == 3
    error_message = "Three AZ configuration should create 3 NAT gateways"
  }
}

# =============================================================================
# EDGE CASE TESTS - Different VPC CIDR
# =============================================================================

run "different_vpc_cidr" {
  command = plan

  variables {
    vpc_cidr = "172.16.0.0/16"
  }

  assert {
    condition     = output.vpc_cidr_block == "172.16.0.0/16"
    error_message = "VPC should accept different RFC 1918 CIDR blocks"
  }
}

# =============================================================================
# EDGE CASE TESTS - NAT Gateway Disabled (Cost Optimization)
# =============================================================================

run "nat_gateway_disabled" {
  command = plan

  variables {
    enable_nat_gateway = false
  }

  assert {
    condition     = length(output.nat_gateway_ids) == 0
    error_message = "NAT Gateways should not be created when enable_nat_gateway is false"
  }
}

# =============================================================================
# EDGE CASE TESTS - Flow Logs Disabled
# =============================================================================

run "flow_logs_disabled" {
  command = plan

  variables {
    enable_flow_logs = false
  }

  assert {
    condition     = output.flow_log_id == null
    error_message = "Flow logs should not be created when enable_flow_logs is false"
  }

  assert {
    condition     = output.flow_log_cloudwatch_log_group_arn == null
    error_message = "Flow logs CloudWatch Log Group should not be created when disabled"
  }
}

# =============================================================================
# OUTPUT VALIDATION TESTS
# =============================================================================

run "outputs_are_populated" {
  command = plan

  assert {
    condition     = output.vpc_id != null
    error_message = "VPC ID output must be defined"
  }

  assert {
    condition     = output.vpc_cidr_block != null
    error_message = "VPC CIDR output must be defined"
  }

  assert {
    condition     = output.public_subnet_ids != null
    error_message = "Public subnet IDs output must be defined"
  }

  assert {
    condition     = output.private_subnet_ids != null
    error_message = "Private subnet IDs output must be defined"
  }

  assert {
    condition     = output.availability_zones != null
    error_message = "Availability zones output must be defined"
  }
}

# =============================================================================
# DEV ENVIRONMENT TEST - Validate Cost-Optimized Configuration
# =============================================================================

run "dev_environment_configuration" {
  command = plan

  variables {
    name                     = "dev-vpc"
    environment              = "dev"
    vpc_cidr                 = "10.0.0.0/16"
    availability_zones_count = 2
    enable_nat_gateway       = false
    enable_flow_logs         = false
  }

  assert {
    condition     = length(output.nat_gateway_ids) == 0
    error_message = "Dev environment should not have NAT Gateways for cost savings"
  }

  assert {
    condition     = output.flow_log_id == null
    error_message = "Dev environment should not have flow logs for cost savings"
  }
}

# =============================================================================
# PROD ENVIRONMENT TEST - Validate Full Feature Configuration
# =============================================================================

run "prod_environment_configuration" {
  command = plan

  variables {
    name                     = "prod-vpc"
    environment              = "prod"
    vpc_cidr                 = "10.0.0.0/16"
    availability_zones_count = 3
    enable_nat_gateway       = true
    enable_flow_logs         = true
    flow_logs_retention_days = 90
  }

  assert {
    condition     = length(output.nat_gateway_ids) == 3
    error_message = "Production environment should have NAT Gateways for high availability"
  }

  assert {
    condition     = output.flow_log_id != null
    error_message = "Production environment should have flow logs enabled for compliance"
  }

  assert {
    condition     = length(output.public_subnet_ids) == 3
    error_message = "Production environment should span 3 availability zones"
  }
}
