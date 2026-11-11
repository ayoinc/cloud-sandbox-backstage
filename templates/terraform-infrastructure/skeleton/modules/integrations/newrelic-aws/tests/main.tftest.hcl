mock_provider "aws" {}

mock_provider "newrelic" {
  mock_data "newrelic_account" {
    defaults = {
      id = "7654321"
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

run "links_the_provider_account" {
  command = plan

  assert {
    condition     = length(data.newrelic_account.current) == 1
    error_message = "The provider account must be looked up when no account ID is passed."
  }

  assert {
    condition     = newrelic_cloud_aws_link_account.this.account_id == 7654321
    error_message = "The AWS account must be linked to the account of the provider."
  }

  assert {
    condition     = newrelic_cloud_aws_link_account.this.metric_collection_mode == "PULL"
    error_message = "The account must be linked for API polling."
  }

  assert {
    condition     = jsondecode(aws_iam_role.newrelic.assume_role_policy).Statement[0].Condition.StringEquals["sts:ExternalId"] == "7654321"
    error_message = "The role must require the New Relic account ID as external ID."
  }

  assert {
    condition     = jsondecode(aws_iam_role.newrelic.assume_role_policy).Statement[0].Principal.AWS == "arn:aws:iam::754728514883:root"
    error_message = "The role must trust the New Relic AWS account only."
  }

  assert {
    condition     = aws_iam_role.newrelic.name == "acme-dev-newrelic-integration"
    error_message = "The role name must derive from name_prefix."
  }

  assert {
    condition     = aws_iam_role.newrelic.tags == var.tags
    error_message = "The role must carry the tags."
  }
}

run "links_an_explicit_account" {
  command = plan

  variables {
    newrelic_account_id = 1234567
  }

  assert {
    condition     = length(data.newrelic_account.current) == 0
    error_message = "No lookup is needed when the account ID is passed."
  }

  assert {
    condition     = newrelic_cloud_aws_link_account.this.account_id == 1234567 && newrelic_cloud_aws_integrations.this.account_id == 1234567
    error_message = "The link and the integrations must target the given account."
  }

  assert {
    condition     = jsondecode(aws_iam_role.newrelic.assume_role_policy).Statement[0].Condition.StringEquals["sts:ExternalId"] == "1234567"
    error_message = "The external ID must be the given account ID."
  }
}

run "grants_read_only_actions" {
  command = plan

  assert {
    condition = alltrue([
      for action in jsondecode(aws_iam_policy.newrelic.policy).Statement[0].Action :
      can(regex("^[a-z0-9]+:(Describe|Get|List|BatchGet)[A-Za-z]+$", action))
    ])
    error_message = "The policy may only contain describe, get and list actions without wildcards."
  }

  assert {
    condition     = length(aws_iam_policy.newrelic.policy) <= 6144
    error_message = "The policy must fit into one managed policy."
  }

  assert {
    condition = alltrue([
      for integration in ["vpc", "alb", "elb", "cloudfront", "aws_wafv2", "auto_scaling", "ec2", "ebs", "rds", "doc_db", "elasticache", "dynamodb", "s3"] :
      length(newrelic_cloud_aws_integrations.this[integration]) == 1
    ])
    error_message = "Every service the stack can create must have its integration enabled."
  }
}

run "rejects_invalid_name_prefix" {
  command = plan

  variables {
    name_prefix = "this-prefix-is-longer-than-24-characters"
  }

  expect_failures = [var.name_prefix]
}
