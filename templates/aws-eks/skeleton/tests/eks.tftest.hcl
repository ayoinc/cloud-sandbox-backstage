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
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }
}

mock_provider "tls" {}

# -----------------------------------------------------------------------------
# Test: Basic EKS Cluster Configuration
# -----------------------------------------------------------------------------
run "eks_cluster_basic_config" {
  command = plan

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
  command = plan

  variables {
    name                    = "secure-cluster"
    environment             = "prod"
    endpoint_private_access = true
    endpoint_public_access  = false  # Private only for production
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
  command = plan

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
  command = plan

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
  command = plan

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
  command = plan

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
  command = plan

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
  command = plan

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
  command = plan

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
  command = plan

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
  command = plan

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
  command = plan

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
  command = plan

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
