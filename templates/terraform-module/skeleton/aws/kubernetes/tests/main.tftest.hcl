mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "eu-west-2"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }

  mock_data "aws_vpc" {
    defaults = {
      cidr_block = "10.0.0.0/16"
    }
  }
}

variables {
  project_name = "My_Project"
  environment  = "dev"
  vpc_id       = "vpc-0123456789abcdef0"
  subnet_ids   = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
}

run "defaults" {
  command = plan

  assert {
    condition     = aws_eks_cluster.main.name == "my-project-dev"
    error_message = "The cluster name must be the name prefix."
  }

  assert {
    condition     = aws_eks_cluster.main.vpc_config[0].endpoint_private_access == true && aws_eks_cluster.main.vpc_config[0].endpoint_public_access == false
    error_message = "The API endpoint must be private by default."
  }

  assert {
    condition     = length(aws_eks_cluster.main.enabled_cluster_log_types) == 5
    error_message = "All control plane log types must be enabled by default."
  }

  assert {
    condition     = length(aws_kms_key.secrets) == 1 && aws_kms_key.secrets[0].enable_key_rotation == true
    error_message = "A rotating KMS key for secrets must be created by default."
  }

  assert {
    condition     = aws_eks_cluster.main.encryption_config[0].resources == toset(["secrets"])
    error_message = "Kubernetes secrets must be envelope encrypted."
  }

  assert {
    condition     = aws_eks_cluster.main.access_config[0].authentication_mode == "API_AND_CONFIG_MAP"
    error_message = "Access entries must be enabled."
  }

  assert {
    condition     = aws_cloudwatch_log_group.eks.name == "/aws/eks/my-project-dev/cluster" && aws_cloudwatch_log_group.eks.retention_in_days == 30
    error_message = "The control plane log group must be pre-created with retention."
  }

  assert {
    condition     = aws_eks_node_group.main.scaling_config[0].min_size == 1 && aws_eks_node_group.main.scaling_config[0].max_size == 5 && aws_eks_node_group.main.scaling_config[0].desired_size == 2
    error_message = "Default node scaling must be 1/2/5."
  }

  assert {
    condition     = aws_eks_node_group.main.capacity_type == "ON_DEMAND" && aws_eks_node_group.main.ami_type == "AL2023_x86_64_STANDARD" && aws_eks_node_group.main.instance_types == tolist(["t3.medium"])
    error_message = "Default node group settings are wrong."
  }

  assert {
    condition     = aws_launch_template.node.metadata_options[0].http_tokens == "required" && aws_launch_template.node.block_device_mappings[0].ebs[0].encrypted == "true" && aws_launch_template.node.block_device_mappings[0].ebs[0].volume_size == 50
    error_message = "Nodes must require IMDSv2 and use an encrypted 50 GB root volume."
  }

  assert {
    condition     = length(aws_eks_addon.ebs_csi_driver) == 1 && length(aws_iam_role.ebs_csi) == 1
    error_message = "The EBS CSI driver is installed by default."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.cluster_api) == 0
    error_message = "No extra API ingress may be open by default."
  }
}

run "public_endpoint_with_allow_list" {
  command = plan

  variables {
    cluster_version      = "1.34"
    enable_public_access = true
    public_access_cidrs  = ["203.0.113.0/24"]
    private_access_cidrs = ["10.0.0.0/16", "10.8.0.0/24"]
    enabled_log_types    = ["audit"]
    log_retention_days   = 90
  }

  assert {
    condition     = aws_eks_cluster.main.version == "1.34"
    error_message = "cluster_version must be applied."
  }

  assert {
    condition     = aws_eks_cluster.main.vpc_config[0].endpoint_public_access == true && aws_eks_cluster.main.vpc_config[0].public_access_cidrs == toset(["203.0.113.0/24"])
    error_message = "The public endpoint must be limited to the allow-list."
  }

  assert {
    condition     = aws_eks_cluster.main.vpc_config[0].endpoint_private_access == true
    error_message = "The private endpoint stays enabled."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.cluster_api) == 2 && aws_vpc_security_group_ingress_rule.cluster_api[1].cidr_ipv4 == "10.8.0.0/24" && aws_vpc_security_group_ingress_rule.cluster_api[1].from_port == 443
    error_message = "Private networks must get HTTPS access to the API."
  }

  assert {
    condition     = aws_eks_cluster.main.enabled_cluster_log_types == toset(["audit"]) && aws_cloudwatch_log_group.eks.retention_in_days == 90
    error_message = "Log types and retention must be applied."
  }
}

run "existing_kms_key" {
  command = plan

  variables {
    create_kms_key = false
    kms_key_arn    = "arn:aws:kms:eu-west-2:123456789012:key/11111111-2222-3333-4444-555555555555"
  }

  assert {
    condition     = length(aws_kms_key.secrets) == 0 && length(aws_kms_alias.secrets) == 0
    error_message = "No key may be created when an existing key is used."
  }

  assert {
    condition     = aws_eks_cluster.main.encryption_config[0].provider[0].key_arn == var.kms_key_arn && aws_cloudwatch_log_group.eks.kms_key_id == var.kms_key_arn
    error_message = "The supplied key must encrypt secrets and the log group."
  }

  assert {
    condition     = output.secrets_kms_key_arn == var.kms_key_arn
    error_message = "secrets_kms_key_arn must report the supplied key."
  }
}

run "spot_nodes_without_ebs_csi" {
  command = plan

  variables {
    capacity_type         = "SPOT"
    node_instance_types   = ["m6i.large", "m5.large"]
    node_disk_size        = 100
    node_min_size         = 2
    node_max_size         = 8
    node_desired_size     = 4
    enable_ebs_csi_driver = false
    node_labels           = { workload = "batch" }
    node_taints = [{
      key    = "spot"
      value  = "true"
      effect = "NO_SCHEDULE"
    }]
  }

  assert {
    condition     = aws_eks_node_group.main.capacity_type == "SPOT" && length(aws_eks_node_group.main.instance_types) == 2
    error_message = "Spot capacity and instance types must be applied."
  }

  assert {
    condition     = aws_eks_node_group.main.scaling_config[0].min_size == 2 && aws_eks_node_group.main.scaling_config[0].max_size == 8 && aws_eks_node_group.main.scaling_config[0].desired_size == 4
    error_message = "Node scaling must be applied."
  }

  assert {
    condition     = aws_eks_node_group.main.labels["workload"] == "batch" && aws_eks_node_group.main.labels["environment"] == "dev"
    error_message = "Custom labels must be merged with the environment label."
  }

  assert {
    condition     = one(aws_eks_node_group.main.taint).effect == "NO_SCHEDULE"
    error_message = "Taints must be applied."
  }

  assert {
    condition     = aws_launch_template.node.block_device_mappings[0].ebs[0].volume_size == 100
    error_message = "node_disk_size must be applied."
  }

  assert {
    condition     = length(aws_eks_addon.ebs_csi_driver) == 0 && length(aws_iam_role.ebs_csi) == 0
    error_message = "Disabling the EBS CSI driver must remove the addon and its role."
  }
}

run "requires_vpc" {
  command = plan

  variables {
    vpc_id = null
  }

  expect_failures = [var.vpc_id]
}

run "requires_two_subnets" {
  command = plan

  variables {
    subnet_ids = []
  }

  expect_failures = [var.subnet_ids]
}

run "public_access_requires_allow_list" {
  command = plan

  variables {
    enable_public_access = true
  }

  expect_failures = [var.enable_public_access]
}

run "rejects_open_public_endpoint" {
  command = plan

  variables {
    enable_public_access = true
    public_access_cidrs  = ["0.0.0.0/0"]
  }

  expect_failures = [var.public_access_cidrs]
}

run "existing_key_must_be_given" {
  command = plan

  variables {
    create_kms_key = false
  }

  expect_failures = [aws_eks_cluster.main]
}
