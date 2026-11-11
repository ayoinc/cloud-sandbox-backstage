mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-west-2a", "eu-west-2b", "eu-west-2c", "eu-west-2d", "eu-west-2e"]
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
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "The VPC must use the default CIDR."
  }

  assert {
    condition     = aws_vpc.main.tags["Name"] == "my-project-dev-vpc"
    error_message = "Names must be derived from the sanitised project name and environment."
  }

  assert {
    condition     = length(aws_subnet.public) == 3 && length(aws_subnet.private) == 3 && length(aws_subnet.database) == 3
    error_message = "Three subnets per tier are expected by default."
  }

  assert {
    condition     = aws_subnet.public[0].cidr_block == "10.0.0.0/20" && aws_subnet.private[0].cidr_block == "10.0.80.0/20" && aws_subnet.database[0].cidr_block == "10.0.160.0/20"
    error_message = "Subnet tiers must not overlap."
  }

  assert {
    condition     = aws_subnet.private[2].availability_zone == "eu-west-2c"
    error_message = "Zones must come from the region when availability_zones is empty."
  }

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.map_public_ip_on_launch == false])
    error_message = "Public subnets must not auto-assign public IPs by default."
  }

  assert {
    condition     = length(aws_nat_gateway.main) == 3 && length(aws_route_table.private) == 3 && length(aws_route.private_nat) == 3
    error_message = "One NAT gateway and private route table per zone is expected by default."
  }

  assert {
    condition     = length(aws_flow_log.main) == 1 && aws_flow_log.main[0].traffic_type == "ALL"
    error_message = "Flow logs must be enabled by default."
  }

  assert {
    condition     = aws_cloudwatch_log_group.flow_logs[0].name == "/aws/vpc/my-project-dev/flow-logs" && aws_cloudwatch_log_group.flow_logs[0].retention_in_days == 30
    error_message = "Flow log group name or retention is wrong."
  }
}

run "explicit_zones_single_nat" {
  command = plan

  variables {
    vpc_cidr           = "10.20.0.0/20"
    availability_zones = ["us-east-1a", "us-east-1b"]
    single_nat         = true
  }

  assert {
    condition     = length(aws_subnet.private) == 2 && aws_subnet.private[1].availability_zone == "us-east-1b"
    error_message = "Subnets must follow the explicit zone list."
  }

  assert {
    condition     = aws_subnet.database[1].cidr_block == "10.20.11.0/24"
    error_message = "Subnets must be /24 slices of a /20 VPC."
  }

  assert {
    condition     = length(aws_nat_gateway.main) == 1 && length(aws_eip.nat) == 1 && length(aws_route_table.private) == 1
    error_message = "single_nat must create exactly one NAT gateway and one private route table."
  }

  assert {
    condition     = length(aws_route_table_association.private) == 2 && length(aws_route_table_association.database) == 2
    error_message = "Every private and database subnet must be associated with the shared route table."
  }
}

run "no_nat_no_flow_logs" {
  command = plan

  variables {
    enable_nat       = false
    enable_flow_logs = false
    az_count         = 2
  }

  assert {
    condition     = length(aws_nat_gateway.main) == 0 && length(aws_route.private_nat) == 0 && length(aws_route_table.private) == 1
    error_message = "Disabling NAT must leave one private route table without a default route."
  }

  assert {
    condition     = length(aws_flow_log.main) == 0 && length(aws_cloudwatch_log_group.flow_logs) == 0 && length(aws_iam_role.flow_logs) == 0
    error_message = "Disabling flow logs must remove the flow log, log group and role."
  }

  assert {
    condition     = output.flow_log_group_name == null
    error_message = "flow_log_group_name must be null when flow logs are disabled."
  }
}

run "public_ips_and_encrypted_flow_logs" {
  command = plan

  variables {
    map_public_ip_on_launch = true
    kms_key_arn             = "arn:aws:kms:eu-west-2:123456789012:key/11111111-2222-3333-4444-555555555555"
  }

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.map_public_ip_on_launch])
    error_message = "map_public_ip_on_launch must be applied to the public subnets."
  }

  assert {
    condition     = aws_cloudwatch_log_group.flow_logs[0].kms_key_id == "arn:aws:kms:eu-west-2:123456789012:key/11111111-2222-3333-4444-555555555555"
    error_message = "The flow log group must use the supplied KMS key."
  }
}

run "rejects_small_vpc_cidr" {
  command = plan

  variables {
    vpc_cidr = "10.0.0.0/26"
  }

  expect_failures = [var.vpc_cidr]
}

run "rejects_too_many_zones" {
  command = plan

  variables {
    az_count = 6
  }

  expect_failures = [var.az_count]
}
