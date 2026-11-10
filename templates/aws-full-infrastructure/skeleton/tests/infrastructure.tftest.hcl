# Terraform tests. They run against mocked providers, so no AWS account is
# needed: terraform init -backend=false && terraform test

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
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

  mock_data "aws_ssm_parameter" {
    defaults = {
      value = "ami-0123456789abcdef0"
    }
  }
}

mock_provider "random" {}

# The configuration exactly as this repository defines it in
# terraform.auto.tfvars.json.
run "as_configured" {
  command = plan

  assert {
    condition     = output.name == "${var.project_name}-${var.environment}"
    error_message = "Resources must be named <project>-<environment>."
  }

  assert {
    condition     = length(aws_subnet.main) == (var.enable_networking ? length(var.subnet_configurations) : 0)
    error_message = "Every configured subnet must be created when networking is enabled."
  }
}

run "every_category_enabled" {
  command = plan

  variables {
    project_name   = "demo"
    component_name = "demo-infra"
    owner          = "group:default/platform-team"
    environment    = "prod"
    region         = "us-east-1"

    enable_networking  = true
    enable_compute     = true
    enable_containers  = true
    enable_storage     = true
    enable_database    = true
    enable_security    = true
    enable_monitoring  = true
    enable_analytics   = true
    enable_integration = true
    enable_ai_ml       = true

    enable_nat_gateway     = true
    enable_vpn_gateway     = true
    enable_transit_gateway = true
    enable_efs             = true
    enable_dynamodb        = true
    enable_elasticache     = true

    subnet_configurations = [
      { name = "public-a", cidr = "10.0.1.0/24", type = "public" },
      { name = "public-b", cidr = "10.0.2.0/24", type = "public" },
      { name = "private-a", cidr = "10.0.10.0/24", type = "private" },
      { name = "private-b", cidr = "10.0.11.0/24", type = "private" },
      { name = "data-a", cidr = "10.0.20.0/24", type = "isolated" },
    ]
  }

  assert {
    condition     = aws_subnet.main["public-a"].availability_zone != aws_subnet.main["public-b"].availability_zone
    error_message = "Subnets of the same type must be spread over availability zones."
  }

  assert {
    condition     = length(aws_nat_gateway.main) == 1 && length(aws_vpn_gateway.main) == 1 && length(aws_ec2_transit_gateway.main) == 1
    error_message = "The NAT, VPN and transit gateways must be created when enabled."
  }

  assert {
    condition     = length(aws_efs_mount_target.main) == 2
    error_message = "EFS needs a mount target in every private subnet."
  }

  assert {
    condition     = length(aws_eks_cluster.main) == 1 && length(aws_db_instance.main) == 1 && length(aws_dynamodb_table.main) == 1 && length(aws_elasticache_replication_group.main) == 1
    error_message = "The cluster and the databases must be created when enabled."
  }

  assert {
    condition     = length(aws_kinesis_stream.main) == 1 && length(aws_sqs_queue.main) == 1 && length(aws_sagemaker_model_package_group.main) == 1
    error_message = "The analytics, integration and AI/ML categories must be created when enabled."
  }
}

run "every_category_disabled" {
  command = plan

  variables {
    project_name   = "demo"
    component_name = "demo-infra"
    owner          = "group:default/platform-team"
    environment    = "dev"
    region         = "us-east-1"

    enable_networking  = false
    enable_compute     = false
    enable_containers  = false
    enable_storage     = false
    enable_database    = false
    enable_security    = false
    enable_monitoring  = false
    enable_analytics   = false
    enable_integration = false
    enable_ai_ml       = false

    subnet_configurations = []
  }

  assert {
    condition     = length(aws_vpc.main) == 0 && length(aws_subnet.main) == 0
    error_message = "No network may be created when networking is disabled."
  }

  assert {
    condition     = length(aws_autoscaling_group.compute) + length(aws_eks_cluster.main) + length(aws_s3_bucket.main) + length(aws_db_instance.main) == 0
    error_message = "No workload resources may be created when their category is disabled."
  }
}

run "s3_choices" {
  command = plan

  variables {
    s3_bucket_encryption = false
    s3_versioning        = false
    enable_storage       = true
  }

  assert {
    condition     = length(aws_s3_bucket_server_side_encryption_configuration.main) == 0
    error_message = "The bucket must fall back to the S3 managed key when KMS encryption is switched off."
  }

  assert {
    condition     = aws_s3_bucket_versioning.main[0].versioning_configuration[0].status == "Suspended"
    error_message = "Versioning must be suspended when switched off."
  }
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "qa"
  }

  expect_failures = [var.environment]
}
