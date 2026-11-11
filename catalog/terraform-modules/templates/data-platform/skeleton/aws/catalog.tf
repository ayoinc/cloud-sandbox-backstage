# -----------------------------------------------------------------------------
# Data catalog: one Glue database per zone. With the data lake, a crawler per
# zone keeps the tables of that zone's bucket up to date. Without the data
# lake the databases exist for tables that are registered by other means.
# -----------------------------------------------------------------------------

locals {
  catalog_zones = toset(var.enable_data_catalog ? local.zones : [])
  crawls_lake   = var.enable_data_catalog && var.enable_data_lake
  crawled_zones = toset(local.crawls_lake ? local.zones : [])

  # Glue and Athena identifiers allow lowercase letters, digits and underscores.
  catalog_databases = { for zone in local.zones : zone => replace("${local.name_prefix}_${zone}", "-", "_") }

  catalog_arn = "arn:${local.partition}:glue:${var.region}:${local.account_id}:catalog"
  catalog_database_arns = {
    for zone, database in local.catalog_databases : zone => "arn:${local.partition}:glue:${var.region}:${local.account_id}:database/${database}"
  }
  catalog_table_arns = {
    for zone, database in local.catalog_databases : zone => "arn:${local.partition}:glue:${var.region}:${local.account_id}:table/${database}/*"
  }

  # Crawlers and Glue jobs write logs, bookmarks and data with the customer managed key.
  glue_security_configuration = one(aws_glue_security_configuration.this[*].name)
}

resource "aws_glue_catalog_database" "zone" {
  for_each = local.catalog_zones

  name         = local.catalog_databases[each.key]
  description  = "Tables of the ${each.key} zone of the ${local.name_prefix} data platform"
  location_uri = var.enable_data_lake ? "s3://${module.lake[each.key].bucket_name}/" : null

  # With Lake Formation access control, the databases must be created after the
  # account stops granting new databases to every IAM principal.
  depends_on = [aws_lakeformation_data_lake_settings.this]
}

resource "aws_glue_data_catalog_encryption_settings" "this" {
  count = var.enable_encryption && var.enable_data_catalog && var.encrypt_catalog_metadata ? 1 : 0

  data_catalog_encryption_settings {
    encryption_at_rest {
      catalog_encryption_mode = "SSE-KMS"
      sse_aws_kms_key_id      = local.kms_key_arn
    }

    connection_password_encryption {
      return_connection_password_encrypted = false
    }
  }
}

resource "aws_glue_security_configuration" "this" {
  count = var.enable_encryption && (local.crawls_lake || local.etl_native) ? 1 : 0

  name = local.name_prefix

  encryption_configuration {
    s3_encryption {
      s3_encryption_mode = "SSE-KMS"
      kms_key_arn        = local.kms_key_arn
    }

    cloudwatch_encryption {
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn                = local.kms_key_arn
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn                   = local.kms_key_arn
    }
  }
}

data "aws_iam_policy_document" "crawler" {
  count = local.crawls_lake ? 1 : 0

  statement {
    sid       = "ReadLakeObjects"
    actions   = ["s3:GetObject"]
    resources = [for arn in local.lake_bucket_arns : "${arn}/*"]
  }

  statement {
    sid       = "ListLakeBuckets"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = local.lake_bucket_arns
  }

  dynamic "statement" {
    for_each = var.enable_encryption ? [1] : []

    content {
      sid       = "EncryptGlueLogs"
      actions   = ["logs:AssociateKmsKey"]
      resources = ["arn:${local.partition}:logs:${var.region}:${local.account_id}:log-group:/aws-glue/*"]
    }
  }
}

resource "aws_iam_role_policy" "crawler" {
  count = local.crawls_lake ? 1 : 0

  name   = "data-lake"
  role   = module.role["crawler"].role_name
  policy = data.aws_iam_policy_document.crawler[0].json
}

resource "aws_glue_crawler" "zone" {
  for_each = local.crawled_zones

  name          = "${local.name_prefix}-${each.key}"
  description   = "Catalogues the ${each.key} zone of the data lake"
  database_name = aws_glue_catalog_database.zone[each.key].name
  role          = module.role["crawler"].role_arn

  # The pipeline starts the crawlers after the ETL jobs. Without it they run on a schedule.
  schedule               = local.pipeline_enabled ? null : var.crawler_schedule
  security_configuration = local.glue_security_configuration

  s3_target {
    path       = "s3://${module.lake[each.key].bucket_name}/"
    exclusions = ["_errors/**"]
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  depends_on = [
    aws_iam_role_policy.crawler,
    aws_lakeformation_permissions.writer_location,
    aws_lakeformation_permissions.writer_database,
  ]
}
