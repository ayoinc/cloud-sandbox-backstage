# Terraform native tests for AWS VPC module

variables {
  project_name = "test-project"
  environment  = "test"
  vpc_cidr     = "10.0.0.0/16"

  public_subnets = [
    { cidr = "10.0.1.0/24", az = "us-east-1a" },
    { cidr = "10.0.2.0/24", az = "us-east-1b" }
  ]

  private_subnets = [
    { cidr = "10.0.10.0/24", az = "us-east-1a" },
    { cidr = "10.0.11.0/24", az = "us-east-1b" }
  ]

  tags = {
    Test = "true"
  }
}

run "vpc_creation" {
  command = plan

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block should be 10.0.0.0/16"
  }

  assert {
    condition     = aws_vpc.main.enable_dns_hostnames == true
    error_message = "DNS hostnames should be enabled"
  }

  assert {
    condition     = aws_vpc.main.enable_dns_support == true
    error_message = "DNS support should be enabled"
  }
}

run "subnet_creation" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Should create 2 public subnets"
  }

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Should create 2 private subnets"
  }
}

run "tags_applied" {
  command = plan

  assert {
    condition     = aws_vpc.main.tags["Environment"] == "test"
    error_message = "Environment tag should be set to test"
  }

  assert {
    condition     = aws_vpc.main.tags["Project"] == "test-project"
    error_message = "Project tag should be set to test-project"
  }
}
