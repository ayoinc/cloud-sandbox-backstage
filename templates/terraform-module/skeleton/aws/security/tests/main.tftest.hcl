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
}

run "defaults" {
  command = plan

  assert {
    condition     = aws_kms_key.main.enable_key_rotation == true && aws_kms_key.main.multi_region == false
    error_message = "The KMS key must rotate and be single-region by default."
  }

  assert {
    condition     = aws_kms_key.main.deletion_window_in_days == 7
    error_message = "Non-production keys use a 7 day deletion window."
  }

  assert {
    condition     = aws_kms_alias.main.name == "alias/my-project-dev"
    error_message = "The KMS alias must be derived from the name prefix."
  }

  assert {
    condition     = aws_iam_role.application.name == "my-project-dev-app-role"
    error_message = "The application role name is wrong."
  }

  assert {
    condition     = jsondecode(aws_iam_role_policy.s3_access.policy).Statement[1].Resource == "arn:aws:s3:::my-project-dev-*/*"
    error_message = "S3 access must be scoped to the project's buckets."
  }

  assert {
    condition     = aws_secretsmanager_secret.app_secrets.name == "my-project/dev/app-secrets" && aws_secretsmanager_secret.app_secrets.recovery_window_in_days == 0
    error_message = "The application secret name or recovery window is wrong."
  }

  assert {
    condition     = length(aws_security_group.bastion) == 0 && length(aws_wafv2_web_acl.main) == 0
    error_message = "Bastion security group and WAF are opt-in."
  }

  assert {
    condition     = output.bastion_security_group_id == null && output.waf_web_acl_arn == null
    error_message = "Outputs of disabled features must be null."
  }
}

run "production" {
  command = plan

  variables {
    environment      = "prod"
    kms_multi_region = true
  }

  assert {
    condition     = aws_kms_key.main.deletion_window_in_days == 30 && aws_kms_key.main.multi_region == true
    error_message = "Production keys use a 30 day deletion window; kms_multi_region must be applied."
  }

  assert {
    condition     = aws_secretsmanager_secret.app_secrets.recovery_window_in_days == 30
    error_message = "Production secrets must keep a 30 day recovery window."
  }
}

run "bastion" {
  command = plan

  variables {
    vpc_id                = "vpc-0123456789abcdef0"
    enable_bastion_sg     = true
    bastion_allowed_cidrs = ["203.0.113.0/24", "198.51.100.7/32"]
  }

  assert {
    condition     = length(aws_security_group.bastion) == 1 && aws_security_group.bastion[0].vpc_id == "vpc-0123456789abcdef0"
    error_message = "The bastion security group must be created in the given VPC."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.bastion_ssh) == 2 && aws_vpc_security_group_ingress_rule.bastion_ssh[1].cidr_ipv4 == "198.51.100.7/32"
    error_message = "One SSH ingress rule per allowed CIDR is expected."
  }

  assert {
    condition     = aws_vpc_security_group_egress_rule.bastion_ssh[0].cidr_ipv4 == "10.0.0.0/16" && aws_vpc_security_group_egress_rule.bastion_ssh[0].to_port == 22
    error_message = "Bastion egress must be limited to SSH inside the VPC."
  }
}

run "waf" {
  command = plan

  variables {
    enable_waf     = true
    waf_rate_limit = 500
  }

  assert {
    condition     = length(aws_wafv2_web_acl.main) == 1 && aws_wafv2_web_acl.main[0].scope == "REGIONAL"
    error_message = "A regional web ACL must be created."
  }

  assert {
    condition     = length(aws_wafv2_web_acl.main[0].rule) == 4
    error_message = "Three managed rule groups and the rate limit rule are expected."
  }

  assert {
    condition     = one([for r in aws_wafv2_web_acl.main[0].rule : r.statement[0].rate_based_statement[0].limit if r.name == "RateLimitRule"]) == 500
    error_message = "waf_rate_limit must be applied to the rate limit rule."
  }
}

run "bastion_requires_vpc" {
  command = plan

  variables {
    enable_bastion_sg = true
  }

  expect_failures = [var.enable_bastion_sg]
}

run "rejects_open_ssh" {
  command = plan

  variables {
    bastion_allowed_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.bastion_allowed_cidrs]
}
