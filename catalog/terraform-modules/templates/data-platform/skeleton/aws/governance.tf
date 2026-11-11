# -----------------------------------------------------------------------------
# Access control: who may read which zone of the data lake.
#
# enable_access_control = false: the consumers' IAM roles read the buckets of
# their zones directly.
# enable_access_control = true: the buckets are registered with Lake Formation
# and the consumers get Lake Formation permissions on the tables of their
# zones instead; their roles have no access to the buckets. Lake Formation
# governs tables, so without the data catalog the consumers keep bucket access.
# -----------------------------------------------------------------------------

locals {
  consumer_zones = {
    warehouse = ["curated"]
    bi        = ["curated"]
    ml        = ["processed", "curated"]
  }

  # Consumers and pipeline roles that exist in this configuration.
  lake_consumers = {
    for key, zones in local.consumer_zones : key => zones if var.enable_data_lake && contains(keys(local.roles), key)
  }
  lake_writers = [for key in ["crawler", "etl"] : key if contains(keys(local.roles), key)]

  lake_formation_governs = var.enable_access_control && var.enable_data_lake && var.enable_data_catalog

  lake_reader_grants = local.lake_formation_governs ? merge([
    for consumer, zones in local.lake_consumers : {
      for zone in zones : "${consumer}/${zone}" => { role = consumer, zone = zone }
    }
  ]...) : {}

  lake_writer_grants = local.lake_formation_governs ? merge([
    for writer in local.lake_writers : {
      for zone in local.zones : "${writer}/${zone}" => { role = writer, zone = zone }
    }
  ]...) : {}

  catalog_default_database_arn = "arn:${local.partition}:glue:${var.region}:${local.account_id}:database/default"
}

data "aws_iam_policy_document" "lake_read" {
  for_each = local.lake_consumers

  # Athena and Redshift need the default database next to the ones they query.
  dynamic "statement" {
    for_each = var.enable_data_catalog ? [1] : []

    content {
      sid = "ReadCatalog"
      actions = [
        "glue:GetDatabase",
        "glue:GetDatabases",
        "glue:GetTable",
        "glue:GetTables",
        "glue:GetPartition",
        "glue:GetPartitions",
        "glue:BatchGetPartition",
      ]
      resources = concat(
        [local.catalog_arn, local.catalog_default_database_arn],
        [for zone in each.value : local.catalog_database_arns[zone]],
        [for zone in each.value : local.catalog_table_arns[zone]],
      )
    }
  }

  dynamic "statement" {
    for_each = local.lake_formation_governs ? [1] : []

    content {
      sid       = "LakeFormationCredentials"
      actions   = ["lakeformation:GetDataAccess"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = local.lake_formation_governs ? [] : [1]

    content {
      sid       = "ReadZoneObjects"
      actions   = ["s3:GetObject"]
      resources = [for zone in each.value : "${module.lake[zone].bucket_arn}/*"]
    }
  }

  dynamic "statement" {
    for_each = local.lake_formation_governs ? [] : [1]

    content {
      sid       = "ListZoneBuckets"
      actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
      resources = [for zone in each.value : module.lake[zone].bucket_arn]
    }
  }
}

resource "aws_iam_role_policy" "lake_read" {
  for_each = local.lake_consumers

  name   = "data-lake"
  role   = module.role[each.key].role_name
  policy = data.aws_iam_policy_document.lake_read[each.key].json
}

# --- Lake Formation ------------------------------------------------------------

data "aws_iam_session_context" "current" {
  count = var.enable_access_control ? 1 : 0

  arn = data.aws_caller_identity.current.arn
}

# These settings apply to the whole account in this region: the listed
# principals become the data lake administrators, and new databases and tables
# are no longer granted to every IAM principal.
resource "aws_lakeformation_data_lake_settings" "this" {
  count = var.enable_access_control ? 1 : 0

  admins = toset(concat([data.aws_iam_session_context.current[0].issuer_arn], var.lake_formation_admin_arns))
}

data "aws_iam_policy_document" "lakeformation" {
  count = var.enable_access_control && var.enable_data_lake ? 1 : 0

  statement {
    sid       = "LakeObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [for arn in local.lake_bucket_arns : "${arn}/*"]
  }

  statement {
    sid       = "LakeBuckets"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = local.lake_bucket_arns
  }
}

resource "aws_iam_role_policy" "lakeformation" {
  count = var.enable_access_control && var.enable_data_lake ? 1 : 0

  name   = "data-lake"
  role   = module.role["lakeformation"].role_name
  policy = data.aws_iam_policy_document.lakeformation[0].json
}

resource "aws_lakeformation_resource" "lake" {
  for_each = var.enable_access_control ? local.lake_zones : toset([])

  arn      = module.lake[each.key].bucket_arn
  role_arn = module.role["lakeformation"].role_arn

  depends_on = [
    aws_lakeformation_data_lake_settings.this,
    aws_iam_role_policy.lakeformation,
  ]
}

resource "aws_lakeformation_permissions" "reader_database" {
  for_each = local.lake_reader_grants

  principal   = module.role[each.value.role].role_arn
  permissions = ["DESCRIBE"]

  database {
    name = aws_glue_catalog_database.zone[each.value.zone].name
  }
}

resource "aws_lakeformation_permissions" "reader_tables" {
  for_each = local.lake_reader_grants

  principal   = module.role[each.value.role].role_arn
  permissions = ["SELECT", "DESCRIBE"]

  table {
    database_name = aws_glue_catalog_database.zone[each.value.zone].name
    wildcard      = true
  }
}

resource "aws_lakeformation_permissions" "writer_database" {
  for_each = local.lake_writer_grants

  principal   = module.role[each.value.role].role_arn
  permissions = ["CREATE_TABLE", "ALTER", "DESCRIBE"]

  database {
    name = aws_glue_catalog_database.zone[each.value.zone].name
  }
}

resource "aws_lakeformation_permissions" "writer_tables" {
  for_each = local.lake_writer_grants

  principal   = module.role[each.value.role].role_arn
  permissions = ["SELECT", "INSERT", "DELETE", "ALTER", "DESCRIBE"]

  table {
    database_name = aws_glue_catalog_database.zone[each.value.zone].name
    wildcard      = true
  }
}

resource "aws_lakeformation_permissions" "writer_location" {
  for_each = local.lake_writer_grants

  principal   = module.role[each.value.role].role_arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.lake[each.value.zone].arn
  }
}

# Spark creates the default database of the catalog in an account that does not
# have one yet, which Lake Formation only allows with this permission.
resource "aws_lakeformation_permissions" "etl_create_database" {
  count = local.lake_formation_governs && var.enable_etl_pipelines ? 1 : 0

  principal        = module.role["etl"].role_arn
  permissions      = ["CREATE_DATABASE"]
  catalog_resource = true

  depends_on = [aws_lakeformation_data_lake_settings.this]
}

# -----------------------------------------------------------------------------
# Data lineage: an Amazon DataZone domain stores OpenLineage events. The ETL
# jobs send one for every dataset they read and write, through the OpenLineage
# listener that Glue 5.0 and EMR 7.5 and later include. Without the ETL jobs
# the domain still accepts events that other tools post to it.
# -----------------------------------------------------------------------------

resource "aws_datazone_domain" "lineage" {
  count = var.enable_data_lineage ? 1 : 0

  name                  = "${local.name_prefix}-lineage"
  description           = "Data lineage of the ${local.name_prefix} data platform"
  domain_execution_role = module.role["datazone"].role_arn
  kms_key_identifier    = local.kms_key_arn
  skip_deletion_check   = !local.is_production

  depends_on = [aws_iam_role_policy_attachment.use_data_key]
}

locals {
  lineage_spark_conf = var.enable_data_lineage ? {
    "spark.extraListeners"                                  = "io.openlineage.spark.agent.OpenLineageSparkListener"
    "spark.openlineage.transport.type"                      = "amazon_datazone_api"
    "spark.openlineage.transport.domainId"                  = aws_datazone_domain.lineage[0].id
    "spark.openlineage.columnLineage.datasetLineageEnabled" = "True"
    "spark.glue.accountId"                                  = local.account_id
  } : {}
}
