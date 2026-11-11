locals {
  # AWS account New Relic assumes the role from.
  newrelic_aws_account_id = "754728514883"

  # Read-only actions New Relic documents for each enabled integration. The
  # DocumentDB and WAFv2 integrations need the common actions only.
  integration_actions = {
    common = [
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "config:BatchGetResourceConfig",
      "config:ListDiscoveredResources",
      "tag:GetResources",
    ]
    vpc = [
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNatGateways",
      "ec2:DescribeNetworkAcls",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpnConnections",
    ]
    load_balancers = [
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeLoadBalancerPolicies",
      "elasticloadbalancing:DescribeLoadBalancerPolicyTypes",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetGroups",
    ]
    cloudfront = [
      "cloudfront:ListDistributions",
      "cloudfront:ListStreamingDistributions",
      "cloudfront:ListTagsForResource",
    ]
    auto_scaling = [
      "autoscaling:DescribeAccountLimits",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribePolicies",
      "autoscaling:DescribeTags",
    ]
    ec2 = [
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstances",
    ]
    ebs = [
      "ec2:DescribeVolumeAttribute",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeVolumes",
    ]
    rds = [
      "rds:DescribeDBClusters",
      "rds:DescribeDBInstances",
      "rds:ListTagsForResource",
    ]
    elasticache = [
      "elasticache:DescribeCacheClusters",
      "elasticache:ListTagsForResource",
    ]
    dynamodb = [
      "dynamodb:DescribeGlobalTable",
      "dynamodb:DescribeLimits",
      "dynamodb:DescribeTable",
      "dynamodb:ListGlobalTables",
      "dynamodb:ListTables",
      "dynamodb:ListTagsOfResource",
    ]
    s3 = [
      "s3:GetAccelerateConfiguration",
      "s3:GetAnalyticsConfiguration",
      "s3:GetBucketAcl",
      "s3:GetBucketCORS",
      "s3:GetBucketLocation",
      "s3:GetBucketLogging",
      "s3:GetBucketNotification",
      "s3:GetBucketPolicy",
      "s3:GetBucketRequestPayment",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketWebsite",
      "s3:GetEncryptionConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:ListAllMyBuckets",
    ]
  }
}

resource "aws_iam_role" "newrelic" {
  name        = "${var.name_prefix}-newrelic-integration"
  description = "Assumed by New Relic to read metrics and resource metadata of this account."
  tags        = var.tags

  # New Relic presents the ID of the linked New Relic account as external ID.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { AWS = "arn:aws:iam::${local.newrelic_aws_account_id}:root" }
      Condition = {
        StringEquals = {
          "sts:ExternalId" = tostring(local.newrelic_account_id)
        }
      }
    }]
  })
}

resource "aws_iam_policy" "newrelic" {
  name        = "${var.name_prefix}-newrelic-integration"
  description = "Read-only actions of the New Relic integrations enabled for this account."
  tags        = var.tags

  # Describe and list calls of a monitoring integration cover every resource of
  # the account; none of the actions reads data stored in a resource.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = sort(distinct(flatten(values(local.integration_actions))))
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "newrelic" {
  role       = aws_iam_role.newrelic.name
  policy_arn = aws_iam_policy.newrelic.arn
}
