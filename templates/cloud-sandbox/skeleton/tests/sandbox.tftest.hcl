# =============================================================================
# Cloud Sandbox Terraform Tests
# =============================================================================
# These tests validate the sandbox infrastructure configuration and ensure
# the modular structure works correctly with various optional components.
#
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Test Variables
# -----------------------------------------------------------------------------
variables {
  name            = "test-sandbox"
  environment     = "test"
  region          = "us-east-1"
  vpc_cidr        = "10.0.0.0/16"
  public_subnets  = 2
  private_subnets = 2
  include_bastion = true
  include_eks     = false
  include_rds     = false
  tags            = {}
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

run "sandbox_module_is_valid" {
  command = plan

  assert {
    condition     = output.vpc_id != null
    error_message = "VPC ID output must be defined"
  }
}

run "public_subnets_configuration" {
  command = plan

  assert {
    condition     = length(output.public_subnet_ids) == 2
    error_message = "Number of public subnets must match the public_subnets variable (2)"
  }
}

run "private_subnets_configuration" {
  command = plan

  assert {
    condition     = length(output.private_subnet_ids) == 2
    error_message = "Number of private subnets must match the private_subnets variable (2)"
  }
}

# =============================================================================
# OPTIONAL COMPONENT TESTS - Bastion
# =============================================================================

run "bastion_enabled" {
  command = plan

  variables {
    include_bastion = true
  }

  assert {
    condition     = output.bastion_public_ip != null
    error_message = "Bastion public IP should be available when bastion is enabled"
  }
}

run "bastion_disabled" {
  command = plan

  variables {
    include_bastion = false
  }

  assert {
    condition     = output.bastion_public_ip == null
    error_message = "Bastion public IP should be null when bastion is disabled"
  }
}

# =============================================================================
# OPTIONAL COMPONENT TESTS - EKS
# =============================================================================

run "eks_enabled" {
  command = plan

  variables {
    include_eks = true
  }

  assert {
    condition     = output.eks_cluster_endpoint != null
    error_message = "EKS cluster endpoint should be available when EKS is enabled"
  }
}

run "eks_disabled" {
  command = plan

  variables {
    include_eks = false
  }

  assert {
    condition     = output.eks_cluster_endpoint == null
    error_message = "EKS cluster endpoint should be null when EKS is disabled"
  }
}

# =============================================================================
# OPTIONAL COMPONENT TESTS - RDS
# =============================================================================

run "rds_enabled" {
  command = plan

  variables {
    include_rds = true
  }

  assert {
    condition     = output.rds_endpoint != null
    error_message = "RDS endpoint should be available when RDS is enabled"
  }
}

run "rds_disabled" {
  command = plan

  variables {
    include_rds = false
  }

  assert {
    condition     = output.rds_endpoint == null
    error_message = "RDS endpoint should be null when RDS is disabled"
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
    error_message = "VPC CIDR must be a valid RFC 1918 private IP range"
  }
}

run "different_vpc_cidr" {
  command = plan

  variables {
    vpc_cidr = "172.16.0.0/16"
  }

  assert {
    condition     = output.vpc_id != null
    error_message = "VPC should accept different RFC 1918 CIDR blocks"
  }
}

# =============================================================================
# EDGE CASE TESTS - Minimal Configuration
# =============================================================================

run "minimal_configuration" {
  command = plan

  variables {
    public_subnets  = 1
    private_subnets = 0
    include_bastion = false
    include_eks     = false
    include_rds     = false
  }

  assert {
    condition     = length(output.public_subnet_ids) == 1
    error_message = "Minimal config should create 1 public subnet"
  }

  assert {
    condition     = length(output.private_subnet_ids) == 0
    error_message = "Minimal config should create 0 private subnets"
  }
}

# =============================================================================
# EDGE CASE TESTS - Full Configuration
# =============================================================================

run "full_configuration" {
  command = plan

  variables {
    public_subnets  = 3
    private_subnets = 3
    include_bastion = true
    include_eks     = true
    include_rds     = true
  }

  assert {
    condition     = length(output.public_subnet_ids) == 3
    error_message = "Full config should create 3 public subnets"
  }

  assert {
    condition     = length(output.private_subnet_ids) == 3
    error_message = "Full config should create 3 private subnets"
  }

  assert {
    condition     = output.bastion_public_ip != null
    error_message = "Full config should have bastion"
  }

  assert {
    condition     = output.eks_cluster_endpoint != null
    error_message = "Full config should have EKS"
  }

  assert {
    condition     = output.rds_endpoint != null
    error_message = "Full config should have RDS"
  }
}

# =============================================================================
# ENVIRONMENT TESTS
# =============================================================================

run "sandbox_environment" {
  command = plan

  variables {
    environment = "sandbox"
  }

  assert {
    condition     = output.vpc_id != null
    error_message = "Sandbox environment should create VPC"
  }
}

run "dev_environment" {
  command = plan

  variables {
    environment = "dev"
  }

  assert {
    condition     = output.vpc_id != null
    error_message = "Dev environment should create VPC"
  }
}

# =============================================================================
# OUTPUT VALIDATION TESTS
# =============================================================================

run "all_outputs_defined" {
  command = plan

  assert {
    condition     = output.vpc_id != null
    error_message = "VPC ID output must be defined"
  }

  assert {
    condition     = output.public_subnet_ids != null
    error_message = "Public subnet IDs output must be defined"
  }

  assert {
    condition     = output.private_subnet_ids != null
    error_message = "Private subnet IDs output must be defined"
  }
}
