# Plans the stack against mocked providers, so the tests need no AWS account.
# Values not set in a run come from terraform.tfvars.

mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }

  mock_data "aws_ssm_parameter" {
    defaults = {
      value = "ami-0123456789abcdef0"
    }
  }
}

mock_provider "tls" {}

run "configured_values" {
  command = plan

  assert {
    condition     = length(module.ecs) == (local.runs_containers ? 1 : 0)
    error_message = "An ECS service exists exactly when compute_type is ecs-fargate or ecs-ec2."
  }

  assert {
    condition     = length(module.instances) == (local.runs_instances ? 1 : 0)
    error_message = "An Auto Scaling group exists exactly when compute_type is ecs-ec2 or ec2-asg."
  }
}

run "ecs_on_fargate" {
  command = plan

  variables {
    compute_type = "ecs-fargate"
  }

  assert {
    condition     = length(module.ecs) == 1 && length(module.instances) == 0
    error_message = "ecs-fargate runs an ECS service without EC2 instances."
  }
}

run "ecs_on_ec2" {
  command = plan

  variables {
    compute_type = "ecs-ec2"
  }

  assert {
    condition     = length(module.ecs) == 1 && length(module.instances) == 1
    error_message = "ecs-ec2 runs an ECS service on an Auto Scaling group."
  }
}

run "ec2_auto_scaling_group" {
  command = plan

  variables {
    compute_type = "ec2-asg"
  }

  assert {
    condition     = length(module.ecs) == 0 && length(module.instances) == 1
    error_message = "ec2-asg runs an Auto Scaling group without ECS."
  }
}

run "production_with_edge_services" {
  command = plan

  variables {
    environment       = "production"
    database_engine   = "mysql"
    enable_waf        = true
    enable_cloudfront = true
  }

  assert {
    condition     = length(module.waf) == 1 && length(module.cloudfront) == 1
    error_message = "enable_waf and enable_cloudfront create the web ACL and the distribution."
  }
}

run "without_edge_services" {
  command = plan

  variables {
    database_engine   = "mariadb"
    enable_waf        = false
    enable_cloudfront = false
  }

  assert {
    condition     = length(module.waf) == 0 && length(module.cloudfront) == 0
    error_message = "No web ACL or distribution is created when both are disabled."
  }
}

run "maximum_below_minimum" {
  command = plan

  variables {
    min_capacity = 4
    max_capacity = 2
  }

  assert {
    condition     = local.max_capacity == 4
    error_message = "A maximum below the minimum is raised to the minimum."
  }
}
