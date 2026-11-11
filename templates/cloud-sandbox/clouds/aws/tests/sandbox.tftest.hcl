# Plan-only tests against a mocked AWS provider: no credentials, no resources.
# Run with: terraform init -backend=false && terraform test

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }

  mock_data "aws_ami" {
    defaults = {
      id = "ami-0123456789abcdef0"
    }
  }
}

variables {
  name            = "test-sandbox"
  environment     = "sandbox"
  region          = "us-east-1"
  vpc_cidr        = "10.0.0.0/16"
  public_subnets  = 2
  private_subnets = 2
  include_bastion = false
  include_eks     = false
  include_rds     = false
}

run "root_module_plans" {
  command = plan

  assert {
    condition     = length(output.public_subnet_ids) == 2
    error_message = "The root module must expose one ID per public subnet."
  }

  assert {
    condition     = length(output.private_subnet_ids) == 2
    error_message = "The root module must expose one ID per private subnet."
  }

  assert {
    condition     = output.bastion_instance_id == null && output.eks_cluster_name == null && output.rds_endpoint == null
    error_message = "Outputs of components that are not included must be null."
  }
}

run "network_layout" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  assert {
    condition     = aws_vpc.this.cidr_block == "10.0.0.0/16"
    error_message = "The VPC must use vpc_cidr."
  }

  assert {
    condition     = aws_subnet.public[*].cidr_block == ["10.0.0.0/20", "10.0.16.0/20"]
    error_message = "Public subnets must be the first /20 blocks of the VPC."
  }

  assert {
    condition     = aws_subnet.private[*].cidr_block == ["10.0.128.0/20", "10.0.144.0/20"]
    error_message = "Private subnets must start at the ninth /20 block of the VPC."
  }

  assert {
    condition     = aws_subnet.public[*].availability_zone == ["us-east-1a", "us-east-1b"]
    error_message = "Subnets must be spread over availability zones."
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "Private subnets need a NAT gateway."
  }

  assert {
    condition     = length(aws_instance.bastion) == 0 && length(aws_eks_cluster.this) == 0 && length(aws_db_instance.this) == 0
    error_message = "Optional components must not be created unless included."
  }
}

run "public_only_network" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  variables {
    public_subnets  = 1
    private_subnets = 0
  }

  assert {
    condition     = length(aws_subnet.public) == 1 && length(aws_subnet.private) == 0
    error_message = "Subnet counts must follow the variables."
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_route_table.private) == 0
    error_message = "No NAT gateway is needed without private subnets."
  }
}

run "four_subnets_wrap_around_zones" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  variables {
    vpc_cidr        = "172.16.0.0/20"
    public_subnets  = 4
    private_subnets = 4
  }

  assert {
    condition     = aws_subnet.public[3].cidr_block == "172.16.3.0/24" && aws_subnet.private[3].cidr_block == "172.16.11.0/24"
    error_message = "Subnets must be /4 slices of the VPC CIDR."
  }

  assert {
    condition     = aws_subnet.public[3].availability_zone == "us-east-1a"
    error_message = "The fourth subnet must reuse the first availability zone."
  }
}

run "bastion_uses_session_manager" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  variables {
    include_bastion = true
  }

  assert {
    condition     = length(aws_instance.bastion) == 1
    error_message = "The bastion must be created when included."
  }

  assert {
    condition     = aws_instance.bastion[0].metadata_options[0].http_tokens == "required"
    error_message = "The bastion must require IMDSv2."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.bastion_ssh) == 0
    error_message = "SSH must stay closed unless bastion_allowed_cidrs is set."
  }
}

run "bastion_ssh_allow_list" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  variables {
    include_bastion       = true
    bastion_allowed_cidrs = ["203.0.113.0/24"]
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.bastion_ssh["203.0.113.0/24"].from_port == 22
    error_message = "Each allowed CIDR must get an SSH ingress rule."
  }
}

run "eks_is_private_by_default" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  variables {
    private_subnets = 0
    include_eks     = true
  }

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "EKS needs two private subnets even when none were requested."
  }

  assert {
    condition     = aws_eks_cluster.this[0].vpc_config[0].endpoint_public_access == false
    error_message = "The EKS API must be private unless eks_public_access_cidrs is set."
  }

  assert {
    condition     = aws_eks_node_group.default[0].scaling_config[0].desired_size == 2
    error_message = "The node group must start with two nodes."
  }
}

run "rds_is_encrypted_and_private" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  variables {
    private_subnets = 1
    include_rds     = true
  }

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "RDS needs two private subnets even when one was requested."
  }

  assert {
    condition     = aws_db_instance.this[0].storage_encrypted && !aws_db_instance.this[0].publicly_accessible
    error_message = "The database must be encrypted and not publicly accessible."
  }

  assert {
    condition     = aws_db_instance.this[0].db_name == "db_test_sandbox"
    error_message = "The database name is derived from the sandbox name."
  }
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    vpc_cidr = "10.0.0.0/28"
  }

  expect_failures = [var.vpc_cidr]
}

run "rejects_too_many_subnets" {
  command = plan

  variables {
    public_subnets = 5
  }

  expect_failures = [var.public_subnets]
}
