terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_organizations_organization" "this" {
  feature_set                   = var.feature_set
  enabled_policy_types          = var.enabled_policy_types
  aws_service_access_principals = var.aws_service_access_principals
}

resource "aws_organizations_organizational_unit" "this" {
  for_each = { for ou in var.organizational_units : ou.name => ou }

  name      = each.value.name
  parent_id = each.value.parent_id != null ? each.value.parent_id : aws_organizations_organization.this.roots[0].id

  depends_on = [aws_organizations_organization.this]
}

resource "aws_organizations_account" "this" {
  for_each = { for account in var.accounts : account.name => account }

  name                       = each.value.name
  email                      = each.value.email
  parent_id                  = each.value.parent_id
  iam_user_access_to_billing = each.value.iam_user_access_to_billing
  role_name                  = each.value.role_name
  tags                       = var.tags

  lifecycle {
    ignore_changes = [role_name]
  }

  depends_on = [aws_organizations_organization.this]
}

resource "aws_organizations_policy" "this" {
  for_each = { for policy in var.service_control_policies : policy.name => policy }

  name        = each.value.name
  description = each.value.description
  content     = each.value.content
  type        = "SERVICE_CONTROL_POLICY"
  tags        = var.tags

  depends_on = [aws_organizations_organization.this]
}

resource "aws_organizations_policy_attachment" "this" {
  for_each = { for attachment in local.policy_attachments : "${attachment.policy_name}-${attachment.target_id}" => attachment }

  policy_id = aws_organizations_policy.this[each.value.policy_name].id
  target_id = each.value.target_id

  depends_on = [
    aws_organizations_policy.this,
    aws_organizations_organizational_unit.this,
    aws_organizations_account.this
  ]
}

locals {
  policy_attachments = flatten([
    for policy in var.service_control_policies : [
      for target_id in policy.target_ids : {
        policy_name = policy.name
        target_id   = target_id
      }
    ]
  ])
}
