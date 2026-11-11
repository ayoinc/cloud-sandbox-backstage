# The list of read-only IAM actions Datadog needs, published by Datadog and
# read at plan time so that it follows the integration as it gains services.
data "datadog_integration_aws_iam_permissions" "this" {}

locals {
  # AWS account that Datadog assumes the role from, per Datadog site. The
  # GovCloud sites use a second account when the monitored account is itself
  # in the aws-us-gov partition.
  datadog_aws_account_ids = {
    "datadoghq.com"     = { commercial = "464622532012", govcloud = null }
    "datadoghq.eu"      = { commercial = "464622532012", govcloud = null }
    "us3.datadoghq.com" = { commercial = "464622532012", govcloud = null }
    "us5.datadoghq.com" = { commercial = "464622532012", govcloud = null }
    "ap1.datadoghq.com" = { commercial = "417141415827", govcloud = null }
    "ap2.datadoghq.com" = { commercial = "412381753143", govcloud = null }
    "uk1.datadoghq.com" = { commercial = "117348461845", govcloud = null }
    "ddog-gov.com"      = { commercial = "392588925713", govcloud = "065115117704" }
    "us2.ddog-gov.com"  = { commercial = "382742775718", govcloud = "486737091498" }
  }

  datadog_aws_account_id = (
    data.aws_partition.current.partition == "aws-us-gov"
    ? local.datadog_aws_account_ids[var.datadog_site].govcloud
    : local.datadog_aws_account_ids[var.datadog_site].commercial
  )

  # A managed policy holds at most 6,144 characters, fewer than the action
  # list needs, so the actions are packed into as many policies as required.
  # Each action costs its length plus the quotes and comma around it.
  permissions            = data.datadog_integration_aws_iam_permissions.this.iam_permissions
  policy_character_limit = 5900
  permission_offsets = [
    for index, _ in local.permissions :
    sum([for permission in slice(local.permissions, 0, index + 1) : length(permission) + 3])
  ]
  permission_policy_index = [
    for offset in local.permission_offsets : floor(offset / local.policy_character_limit)
  ]
  permission_chunks = [
    for policy_index in distinct(local.permission_policy_index) : [
      for index, permission in local.permissions :
      permission if local.permission_policy_index[index] == policy_index
    ]
  ]
}

resource "aws_iam_role" "datadog" {
  name        = local.role_name
  description = "Assumed by Datadog to read metrics and resource metadata of this account."
  tags        = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { AWS = "arn:${data.aws_partition.current.partition}:iam::${local.datadog_aws_account_id}:root" }
      Condition = {
        StringEquals = {
          "sts:ExternalId" = datadog_integration_aws_account.this.auth_config.aws_auth_config_role.external_id
        }
      }
    }]
  })

  lifecycle {
    precondition {
      condition     = local.datadog_aws_account_id != null
      error_message = "An account in the aws-us-gov partition can only be connected to a Datadog GovCloud site: set datadog_site to ddog-gov.com or us2.ddog-gov.com."
    }
  }
}

resource "aws_iam_policy" "datadog" {
  count = length(local.permission_chunks)

  name        = "${local.role_name}-${count.index + 1}"
  description = "Read-only actions of the Datadog AWS integration (part ${count.index + 1} of ${length(local.permission_chunks)})."
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = local.permission_chunks[count.index]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "datadog" {
  count = length(local.permission_chunks)

  role       = aws_iam_role.datadog.name
  policy_arn = aws_iam_policy.datadog[count.index].arn
}

# Resource collection reads the configuration of resources through the
# AWS-managed SecurityAudit policy, as documented by Datadog.
resource "aws_iam_role_policy_attachment" "security_audit" {
  role       = aws_iam_role.datadog.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/SecurityAudit"
}
