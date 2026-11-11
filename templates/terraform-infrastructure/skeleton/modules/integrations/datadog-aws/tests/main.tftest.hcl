mock_provider "aws" {
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
}

mock_provider "datadog" {
  mock_data "datadog_integration_aws_iam_permissions" {
    defaults = {
      iam_permissions = [
        "cloudwatch:GetMetricData",
        "cloudwatch:ListMetrics",
        "ec2:DescribeInstances",
        "tag:GetResources",
      ]
    }
  }
}

variables {
  name_prefix = "acme-dev"
  tags = {
    Project     = "acme"
    Environment = "development"
  }
}

run "connects_the_account" {
  command = plan

  assert {
    condition     = datadog_integration_aws_account.this.aws_account_id == "123456789012"
    error_message = "The integration must register the account of the AWS provider."
  }

  assert {
    condition     = datadog_integration_aws_account.this.auth_config.aws_auth_config_role.role_name == aws_iam_role.datadog.name
    error_message = "Datadog must be told the name of the role created for it."
  }

  assert {
    condition     = aws_iam_role.datadog.name == "acme-dev-datadog-integration"
    error_message = "The role name must derive from name_prefix."
  }

  assert {
    condition     = toset(datadog_integration_aws_account.this.account_tags) == toset(["Project:acme", "Environment:development"])
    error_message = "Tags must be sent to Datadog as key:value account tags."
  }

  assert {
    condition     = datadog_integration_aws_account.this.metrics_config.enabled
    error_message = "Metric collection must be enabled."
  }

  assert {
    condition     = length(aws_iam_policy.datadog) == 1 && length(aws_iam_role_policy_attachment.datadog) == 1
    error_message = "A short action list must fit into one attached policy."
  }

  assert {
    condition     = tolist(jsondecode(aws_iam_policy.datadog[0].policy).Statement[0].Action) == data.datadog_integration_aws_iam_permissions.this.iam_permissions
    error_message = "The policy must grant exactly the actions Datadog publishes."
  }

  assert {
    condition     = aws_iam_role_policy_attachment.security_audit.policy_arn == "arn:aws:iam::aws:policy/SecurityAudit"
    error_message = "The SecurityAudit policy must be attached for resource collection."
  }
}

run "splits_long_action_lists" {
  command = plan

  override_data {
    target = data.datadog_integration_aws_iam_permissions.this
    values = {
      iam_permissions = [for index in range(400) : "service${index}:DescribeSomethingLongEnough"]
    }
  }

  assert {
    condition     = length(aws_iam_policy.datadog) == 3
    error_message = "An action list of about 15,000 characters must be spread over three policies."
  }

  assert {
    condition     = sum([for policy in aws_iam_policy.datadog : length(jsondecode(policy.policy).Statement[0].Action)]) == 400
    error_message = "Every action must be granted exactly once."
  }

  assert {
    condition     = alltrue([for policy in aws_iam_policy.datadog : length(policy.policy) <= 6144])
    error_message = "Every policy must stay within the managed policy size limit."
  }
}

run "accepts_govcloud_account_on_govcloud_site" {
  command = plan

  variables {
    datadog_site = "ddog-gov.com"
  }

  override_data {
    target = data.aws_partition.current
    values = {
      partition = "aws-us-gov"
    }
  }

  assert {
    condition     = datadog_integration_aws_account.this.aws_partition == "aws-us-gov"
    error_message = "The integration must be registered in the partition of the account."
  }

  assert {
    condition     = aws_iam_role_policy_attachment.security_audit.policy_arn == "arn:aws-us-gov:iam::aws:policy/SecurityAudit"
    error_message = "Managed policy ARNs must use the partition of the account."
  }
}

run "rejects_govcloud_account_on_commercial_site" {
  command = plan

  override_data {
    target = data.aws_partition.current
    values = {
      partition = "aws-us-gov"
    }
  }

  expect_failures = [aws_iam_role.datadog]
}

run "rejects_unknown_site" {
  command = plan

  variables {
    datadog_site = "example.com"
  }

  expect_failures = [var.datadog_site]
}

run "rejects_invalid_name_prefix" {
  command = plan

  variables {
    name_prefix = "Not_Valid"
  }

  expect_failures = [var.name_prefix]
}
