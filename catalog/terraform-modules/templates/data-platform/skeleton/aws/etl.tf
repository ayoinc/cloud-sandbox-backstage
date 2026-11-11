# -----------------------------------------------------------------------------
# ETL: two Spark jobs move data from the raw zone to the processed zone and
# from there to the curated zone. etl_engine = native runs them as AWS Glue
# jobs, etl_engine = spark on an EMR Serverless application. Both engines run
# the same scripts from the jobs directory.
# -----------------------------------------------------------------------------

locals {
  etl_native = var.enable_etl_pipelines && var.etl_engine == "native"
  etl_spark  = var.enable_etl_pipelines && var.etl_engine == "spark"

  # EMR Serverless reaches Amazon S3, Glue and KMS on its own, but the DataZone
  # API that receives lineage events only from a VPC with a route to it.
  etl_in_vpc = local.etl_spark && var.enable_data_lineage

  etl_stage_order = ["raw_to_processed", "processed_to_curated"]
  etl_stages = {
    raw_to_processed = {
      state       = "RawToProcessed"
      description = "Cleans the datasets of the raw zone and stores them as Parquet in the processed zone"
      source      = "raw"
      target      = "processed"
    }
    processed_to_curated = {
      state       = "ProcessedToCurated"
      description = "Publishes the datasets of the processed zone to the curated zone"
      source      = "processed"
      target      = "curated"
    }
  }
  enabled_etl_stages = var.enable_etl_pipelines ? local.etl_stages : {}

  etl_job_names = { for key in local.etl_stage_order : key => "${local.name_prefix}-${replace(key, "_", "-")}" }
  etl_script_uris = {
    for key, object in aws_s3_object.etl_script : key => "s3://${object.bucket}/${object.key}"
  }
  etl_arguments = {
    for key, stage in local.enabled_etl_stages : key => merge(
      {
        "--source_path" = local.zone_uris[stage.source]
        "--target_path" = local.zone_uris[stage.target]
      },
      stage.source == "raw" ? { "--source_format" = var.raw_data_format } : {},
    )
  }

  glue_lineage_conf = merge(local.lineage_spark_conf, {
    "spark.openlineage.facets.custom_environment_variables" = "[AWS_DEFAULT_REGION;GLUE_VERSION;GLUE_COMMAND_CRITERIA;GLUE_PYTHON_VERSION;]"
  })
  emr_lineage_conf = merge(local.lineage_spark_conf, {
    "spark.jars" = "/usr/share/aws/datazone-openlineage-spark/lib/DataZoneOpenLineageSpark-1.0.jar"
  })
}

resource "aws_s3_object" "etl_script" {
  for_each = local.enabled_etl_stages

  bucket      = module.artifacts[0].bucket_id
  key         = "jobs/${each.key}.py"
  source      = "${path.module}/jobs/${each.key}.py"
  source_hash = filemd5("${path.module}/jobs/${each.key}.py")
}

data "aws_iam_policy_document" "etl" {
  count = var.enable_etl_pipelines ? 1 : 0

  statement {
    sid       = "ArtifactObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.artifacts_arn}/*"]
  }

  statement {
    sid       = "ArtifactBucket"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [local.artifacts_arn]
  }

  dynamic "statement" {
    for_each = var.enable_data_lake ? [1] : []

    content {
      sid       = "LakeObjects"
      actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      resources = [for arn in local.lake_bucket_arns : "${arn}/*"]
    }
  }

  dynamic "statement" {
    for_each = var.enable_data_lake ? [1] : []

    content {
      sid       = "LakeBuckets"
      actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
      resources = local.lake_bucket_arns
    }
  }

  # Spark looks up the default database of the catalog and its functions when
  # a session starts, and creates the database in an account without one.
  statement {
    sid     = "DefaultDatabase"
    actions = ["glue:GetDatabase", "glue:CreateDatabase", "glue:GetUserDefinedFunctions"]
    resources = [
      local.catalog_arn,
      local.catalog_default_database_arn,
      "arn:${local.partition}:glue:${var.region}:${local.account_id}:userDefinedFunction/default/*",
    ]
  }

  dynamic "statement" {
    for_each = var.enable_data_catalog ? [1] : []

    content {
      sid = "ZoneTables"
      actions = [
        "glue:GetDatabase",
        "glue:GetTable",
        "glue:GetTables",
        "glue:CreateTable",
        "glue:UpdateTable",
        "glue:GetPartition",
        "glue:GetPartitions",
        "glue:BatchGetPartition",
        "glue:CreatePartition",
        "glue:BatchCreatePartition",
        "glue:UpdatePartition",
      ]
      resources = concat([local.catalog_arn], values(local.catalog_database_arns), values(local.catalog_table_arns))
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
    for_each = var.enable_data_lineage ? [1] : []

    content {
      sid       = "PostLineageEvents"
      actions   = ["datazone:PostLineageEvent"]
      resources = [aws_datazone_domain.lineage[0].arn]
    }
  }

  dynamic "statement" {
    for_each = local.etl_native && var.enable_encryption ? [1] : []

    content {
      sid       = "EncryptGlueLogs"
      actions   = ["logs:AssociateKmsKey"]
      resources = ["arn:${local.partition}:logs:${var.region}:${local.account_id}:log-group:/aws-glue/*"]
    }
  }
}

resource "aws_iam_role_policy" "etl" {
  count = var.enable_etl_pipelines ? 1 : 0

  name   = "etl"
  role   = module.role["etl"].role_name
  policy = data.aws_iam_policy_document.etl[0].json
}

# --- etl_engine = native: AWS Glue jobs ----------------------------------------

resource "aws_glue_job" "etl" {
  for_each = local.etl_native ? local.etl_stages : {}

  name        = local.etl_job_names[each.key]
  description = each.value.description
  role_arn    = module.role["etl"].role_arn

  glue_version           = var.glue_version
  worker_type            = var.glue_worker_type
  number_of_workers      = var.glue_number_of_workers
  max_retries            = 0
  timeout                = 120
  security_configuration = local.glue_security_configuration

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = local.etl_script_uris[each.key]
  }

  default_arguments = merge(
    local.etl_arguments[each.key],
    {
      "--job-language"                     = "python"
      "--job-bookmark-option"              = "job-bookmark-disable"
      "--enable-glue-datacatalog"          = "true"
      "--enable-metrics"                   = "true"
      "--enable-continuous-cloudwatch-log" = "true"
      "--TempDir"                          = "s3://${local.artifacts_bucket}/tmp/glue/"
    },
    # Glue takes every Spark setting in the one --conf argument.
    var.enable_data_lineage ? {
      "--conf" = join(" --conf ", [for name, value in local.glue_lineage_conf : "${name}=${value}"])
    } : {},
  )

  execution_property {
    max_concurrent_runs = 1
  }

  depends_on = [aws_iam_role_policy.etl]
}

# --- etl_engine = spark: EMR Serverless application -----------------------------

resource "aws_security_group" "etl" {
  count = local.etl_in_vpc ? 1 : 0

  name        = "${local.name_prefix}-etl"
  description = "Spark jobs of the ${local.name_prefix} EMR Serverless application"
  vpc_id      = module.vpc[0].vpc_id

  tags = {
    Name = "${local.name_prefix}-etl"
  }
}

#trivy:ignore:AVD-AWS-0104 Spark jobs call the AWS service endpoints (Glue, KMS, DataZone) through the NAT gateway; the rule allows HTTPS only.
resource "aws_vpc_security_group_egress_rule" "etl_https" {
  count = local.etl_in_vpc ? 1 : 0

  security_group_id = aws_security_group.etl[0].id
  description       = "HTTPS to the AWS service endpoints"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_emrserverless_application" "etl" {
  count = local.etl_spark ? 1 : 0

  name          = "${local.name_prefix}-etl"
  release_label = var.emr_release_label
  type          = "spark"

  maximum_capacity {
    cpu    = var.emr_maximum_capacity.cpu
    memory = var.emr_maximum_capacity.memory
  }

  auto_start_configuration {
    enabled = true
  }

  auto_stop_configuration {
    enabled              = true
    idle_timeout_minutes = 15
  }

  monitoring_configuration {
    s3_monitoring_configuration {
      log_uri = "s3://${local.artifacts_bucket}/logs/emr-serverless/"
    }
  }

  dynamic "network_configuration" {
    for_each = local.etl_in_vpc ? [1] : []

    content {
      subnet_ids         = module.vpc[0].private_subnet_ids
      security_group_ids = [aws_security_group.etl[0].id]
    }
  }

  dynamic "runtime_configuration" {
    for_each = var.enable_data_lineage ? [1] : []

    content {
      classification = "spark-defaults"
      properties     = local.emr_lineage_conf
    }
  }
}
