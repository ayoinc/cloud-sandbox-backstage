# -----------------------------------------------------------------------------
# Analytics: BI tools and the ML platform query the lake through Amazon Athena.
# Each gets its own workgroup, so their queries are limited and reported
# separately, and an IAM role that may use that workgroup.
# -----------------------------------------------------------------------------

locals {
  athena_consumers = toset(compact([
    var.enable_bi_tools ? "bi" : "",
    var.enable_ml_platform ? "ml" : "",
  ]))
}

resource "aws_athena_workgroup" "consumer" {
  for_each = local.athena_consumers

  name          = "${local.name_prefix}-${each.key}"
  description   = "Queries of the ${each.key} role of the ${local.name_prefix} data platform"
  force_destroy = !local.is_production

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    bytes_scanned_cutoff_per_query     = var.athena_bytes_scanned_cutoff

    result_configuration {
      output_location = "s3://${local.artifacts_bucket}/athena-results/${each.key}/"

      encryption_configuration {
        encryption_option = var.enable_encryption ? "SSE_KMS" : "SSE_S3"
        kms_key_arn       = local.kms_key_arn
      }
    }
  }
}

data "aws_iam_policy_document" "athena" {
  for_each = local.athena_consumers

  statement {
    sid = "RunQueries"
    actions = [
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetQueryResultsStream",
      "athena:BatchGetQueryExecution",
      "athena:ListQueryExecutions",
      "athena:GetWorkGroup",
    ]
    resources = [aws_athena_workgroup.consumer[each.key].arn]
  }

  statement {
    sid = "BrowseCatalog"
    actions = [
      "athena:GetDataCatalog",
      "athena:ListDatabases",
      "athena:GetDatabase",
      "athena:ListTableMetadata",
      "athena:GetTableMetadata",
    ]
    resources = ["arn:${local.partition}:athena:${var.region}:${local.account_id}:datacatalog/AwsDataCatalog"]
  }

  statement {
    sid       = "ListWorkgroups"
    actions   = ["athena:ListDataCatalogs", "athena:ListWorkGroups"]
    resources = ["*"]
  }

  statement {
    sid       = "QueryResultObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:AbortMultipartUpload"]
    resources = ["${local.artifacts_arn}/athena-results/${each.key}/*"]
  }

  statement {
    sid       = "QueryResultBucket"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
    resources = [local.artifacts_arn]
  }
}

resource "aws_iam_role_policy" "athena" {
  for_each = local.athena_consumers

  name   = "athena"
  role   = module.role[each.key].role_name
  policy = data.aws_iam_policy_document.athena[each.key].json
}

# -----------------------------------------------------------------------------
# ML platform: a SageMaker domain in the private subnets. Its users work with
# the execution role, which reads the processed and curated zones and keeps
# its own files under sagemaker/ in the artifacts bucket.
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "ml_workspace" {
  count = var.enable_ml_platform ? 1 : 0

  statement {
    sid       = "WorkspaceObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:AbortMultipartUpload"]
    resources = ["${local.artifacts_arn}/sagemaker/*"]
  }
}

resource "aws_iam_role_policy" "ml_workspace" {
  count = var.enable_ml_platform ? 1 : 0

  name   = "workspace"
  role   = module.role["ml"].role_name
  policy = data.aws_iam_policy_document.ml_workspace[0].json
}

resource "aws_sagemaker_domain" "ml" {
  count = var.enable_ml_platform ? 1 : 0

  domain_name = "${local.name_prefix}-ml"
  auth_mode   = "IAM"
  vpc_id      = module.vpc[0].vpc_id
  subnet_ids  = module.vpc[0].private_subnet_ids
  kms_key_id  = local.kms_key_arn

  default_user_settings {
    execution_role = module.role["ml"].role_arn
  }

  retention_policy {
    home_efs_file_system = local.is_production ? "Retain" : "Delete"
  }
}

resource "aws_sagemaker_user_profile" "ml" {
  for_each = toset(var.enable_ml_platform ? var.ml_user_profiles : [])

  domain_id         = aws_sagemaker_domain.ml[0].id
  user_profile_name = each.key
}
