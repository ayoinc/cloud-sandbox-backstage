# =============================================================================
# EKS Cluster Terraform Tests
# =============================================================================
# Tests for validating EKS cluster configuration, security, and compliance.
# The tests run against the root module which calls the EKS child module.
#
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Test Variables
# -----------------------------------------------------------------------------
variables {
  name               = "test-cluster"
  environment        = "dev"
  vpc_id             = "vpc-12345678"
  private_subnet_ids = ["subnet-1a2b3c4d", "subnet-5e6f7g8h"]

  kubernetes_version      = "1.31"
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["203.0.113.0/24"]

  node_instance_types = ["t3.medium"]
  node_capacity_type  = "SPOT"
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 5
  node_disk_size      = 50

  enable_cluster_autoscaler_irsa           = true
  enable_aws_load_balancer_controller_irsa = true

  tags = {}
}

# -----------------------------------------------------------------------------
# Mock Providers for Testing
# -----------------------------------------------------------------------------
mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"
    }
  }

  mock_resource "aws_eks_cluster" {
    defaults = {
      arn = "arn:aws:eks:us-east-1:123456789012:cluster/mock"
      identity = [{
        oidc = [{ issuer = "https://oidc.eks.us-east-1.amazonaws.com/id/0123456789ABCDEF0123456789ABCDEF" }]
      }]
      certificate_authority = [{ data = "bW9jaw==" }]
    }
  }

  mock_resource "aws_eks_node_group" {
    defaults = {
      arn = "arn:aws:eks:us-east-1:123456789012:nodegroup/mock/mock-nodes/11111111-2222-3333-4444-555555555555"
    }
  }

  mock_resource "aws_iam_openid_connect_provider" {
    defaults = {
      arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/0123456789ABCDEF0123456789ABCDEF"
    }
  }

  mock_data "aws_vpc" {
    defaults = {
      cidr_block = "10.0.0.0/16"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

mock_provider "tls" {
  mock_data "tls_certificate" {
    defaults = {
      certificates = [{ sha1_fingerprint = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280" }]
    }
  }
}

mock_provider "kubernetes" {}

# -----------------------------------------------------------------------------
# Test: Basic EKS Cluster Configuration
# -----------------------------------------------------------------------------
run "eks_cluster_basic_config" {
  command = apply

  assert {
    condition     = output.cluster_name == "test-cluster-dev"
    error_message = "Cluster name should include environment suffix"
  }

  assert {
    condition     = output.cluster_version == "1.31"
    error_message = "Kubernetes version should be set correctly"
  }

  assert {
    condition     = output.cluster_id != null
    error_message = "Cluster ID output must be defined"
  }
}

# -----------------------------------------------------------------------------
# Test: EKS Cluster Security Configuration for Production
# -----------------------------------------------------------------------------
run "eks_cluster_security_prod" {
  command = apply

  variables {
    name                    = "secure-cluster"
    environment             = "prod"
    endpoint_private_access = true
    endpoint_public_access  = false # Private only for production
    node_capacity_type      = "ON_DEMAND"
  }

  assert {
    condition     = output.cluster_name == "secure-cluster-prod"
    error_message = "Production cluster name should be correctly formatted"
  }

  # Note: We can't directly verify VPC config in outputs, but we test the module accepts the config
  assert {
    condition     = output.cluster_id != null
    error_message = "Production cluster should be created successfully"
  }
}

# -----------------------------------------------------------------------------
# Test: Node Group Configuration
# -----------------------------------------------------------------------------
run "eks_node_group_config" {
  command = apply

  variables {
    node_desired_size = 3
    node_max_size     = 6
    node_min_size     = 2
  }

  assert {
    condition     = output.node_group_id != null
    error_message = "Node group should be created"
  }

  assert {
    condition     = output.node_group_arn != null
    error_message = "Node group ARN should be available"
  }
}

# -----------------------------------------------------------------------------
# Test: SPOT Capacity for Dev
# -----------------------------------------------------------------------------
run "eks_node_group_spot_dev" {
  command = apply

  variables {
    environment        = "dev"
    node_capacity_type = "SPOT"
  }

  assert {
    condition     = output.cluster_name == "test-cluster-dev"
    error_message = "Dev cluster should be created with SPOT configuration"
  }
}

# -----------------------------------------------------------------------------
# Test: ON_DEMAND Capacity for Production
# -----------------------------------------------------------------------------
run "eks_node_group_ondemand_prod" {
  command = apply

  variables {
    environment        = "prod"
    node_capacity_type = "ON_DEMAND"
  }

  assert {
    condition     = output.cluster_name == "test-cluster-prod"
    error_message = "Prod cluster should be created with ON_DEMAND configuration"
  }
}

# -----------------------------------------------------------------------------
# Test: IAM Role Outputs
# -----------------------------------------------------------------------------
run "eks_iam_roles" {
  command = apply

  assert {
    condition     = output.cluster_iam_role_arn != null
    error_message = "Cluster IAM role ARN should be available"
  }

  assert {
    condition     = output.node_group_iam_role_arn != null
    error_message = "Node group IAM role ARN should be available"
  }
}

# -----------------------------------------------------------------------------
# Test: OIDC Provider for IRSA
# -----------------------------------------------------------------------------
run "eks_oidc_provider" {
  command = apply

  assert {
    condition     = output.oidc_provider_arn != null
    error_message = "OIDC provider ARN should be available for IRSA"
  }

  assert {
    condition     = output.oidc_issuer != null
    error_message = "OIDC issuer URL should be available"
  }
}

# -----------------------------------------------------------------------------
# Test: Cluster Autoscaler IRSA Role
# -----------------------------------------------------------------------------
run "eks_cluster_autoscaler_irsa" {
  command = apply

  variables {
    enable_cluster_autoscaler_irsa = true
  }

  assert {
    condition     = output.cluster_autoscaler_role_arn != null
    error_message = "Cluster autoscaler IRSA role should be created"
  }
}

# -----------------------------------------------------------------------------
# Test: AWS Load Balancer Controller IRSA Role
# -----------------------------------------------------------------------------
run "eks_aws_lb_controller_irsa" {
  command = apply

  variables {
    enable_aws_load_balancer_controller_irsa = true
  }

  assert {
    condition     = output.aws_lb_controller_role_arn != null
    error_message = "AWS LB Controller IRSA role should be created"
  }
}

# -----------------------------------------------------------------------------
# Test: IRSA Disabled
# -----------------------------------------------------------------------------
run "eks_irsa_disabled" {
  command = apply

  variables {
    enable_cluster_autoscaler_irsa           = false
    enable_aws_load_balancer_controller_irsa = false
  }

  assert {
    condition     = output.cluster_autoscaler_role_arn == null
    error_message = "Cluster autoscaler IRSA role should not be created when disabled"
  }

  assert {
    condition     = output.aws_lb_controller_role_arn == null
    error_message = "AWS LB Controller IRSA role should not be created when disabled"
  }
}

# -----------------------------------------------------------------------------
# Test: Outputs Are Populated
# -----------------------------------------------------------------------------
run "eks_outputs_populated" {
  command = apply

  assert {
    condition     = output.cluster_id != null
    error_message = "Cluster ID output must be defined"
  }

  assert {
    condition     = output.cluster_arn != null
    error_message = "Cluster ARN output must be defined"
  }

  assert {
    condition     = output.cluster_endpoint != null
    error_message = "Cluster endpoint output must be defined"
  }

  assert {
    condition     = output.cluster_security_group_id != null
    error_message = "Cluster security group ID output must be defined"
  }

  assert {
    condition     = output.kubeconfig_command != null
    error_message = "Kubeconfig command output must be defined"
  }
}

# -----------------------------------------------------------------------------
# Test: Three AZ Configuration (Production-like)
# -----------------------------------------------------------------------------
run "eks_three_az_config" {
  command = apply

  variables {
    private_subnet_ids = ["subnet-1a", "subnet-2b", "subnet-3c"]
    node_min_size      = 3
    node_desired_size  = 3
    node_max_size      = 10
  }

  assert {
    condition     = output.cluster_id != null
    error_message = "Cluster should be created with 3 AZ configuration"
  }
}

# -----------------------------------------------------------------------------
# Test: Staging Environment Configuration
# -----------------------------------------------------------------------------
run "eks_staging_config" {
  command = apply

  variables {
    name                = "staging-cluster"
    environment         = "staging"
    node_capacity_type  = "ON_DEMAND"
    node_instance_types = ["t3.large"]
    node_desired_size   = 3
    node_min_size       = 2
    node_max_size       = 6
  }

  assert {
    condition     = output.cluster_name == "staging-cluster-staging"
    error_message = "Staging cluster name should be correctly formatted"
  }
}
