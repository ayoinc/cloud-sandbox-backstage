# The account of the provider configuration, looked up only when no account ID
# is passed in. Its id is the account ID.
data "newrelic_account" "current" {
  count = var.newrelic_account_id == null ? 1 : 0
}

locals {
  newrelic_account_id = var.newrelic_account_id != null ? var.newrelic_account_id : tonumber(data.newrelic_account.current[0].id)
}

# Links the AWS account for API polling: New Relic assumes the role and reads
# CloudWatch metrics and resource metadata on a schedule.
resource "newrelic_cloud_aws_link_account" "this" {
  account_id             = local.newrelic_account_id
  name                   = var.name_prefix
  arn                    = aws_iam_role.newrelic.arn
  metric_collection_mode = "PULL"

  depends_on = [aws_iam_role_policy_attachment.newrelic]
}

# The services this stack can create. Each block needs the matching actions in
# local.integration_actions (iam.tf).
resource "newrelic_cloud_aws_integrations" "this" {
  account_id        = local.newrelic_account_id
  linked_account_id = newrelic_cloud_aws_link_account.this.id

  # Network
  vpc {}

  # Load balancing and CDN
  alb {}
  elb {}
  cloudfront {}
  aws_wafv2 {}

  # Kubernetes worker nodes
  auto_scaling {}
  ec2 {}
  ebs {}

  # Managed databases
  rds {}
  doc_db {}
  elasticache {}
  dynamodb {}

  # Object storage
  s3 {}
}
