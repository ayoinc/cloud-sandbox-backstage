data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  name_prefix   = "${var.project_name}-${var.environment}"
  is_production = var.environment == "production"
  account_id    = data.aws_caller_identity.current.account_id
  partition     = data.aws_partition.current.partition

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Data moves through the zones in this order.
  zones = ["raw", "processed", "curated"]

  # Scripts, logs, temporary files and query results of the ETL jobs, the BI
  # tools and the ML platform live in one artifacts bucket.
  needs_artifacts = var.enable_etl_pipelines || var.enable_bi_tools || var.enable_ml_platform

  # The warehouse, the SageMaker domain and Spark jobs that report lineage run in a VPC.
  needs_network = var.enable_data_warehouse || var.enable_ml_platform || local.etl_in_vpc

  kms_key_arn = one(module.data_key[*].key_arn)

  managed_policies = "arn:${local.partition}:iam::aws:policy"
}

# -----------------------------------------------------------------------------
# Encryption: one customer managed key for every store of the platform when
# enable_encryption is true. Otherwise each service uses its AWS managed key.
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "data_key" {
  count = var.enable_encryption ? 1 : 0

  statement {
    sid       = "AccountAdministration"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
    }
  }

  statement {
    sid = "CloudWatchLogs"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${local.partition}:logs:${var.region}:${local.account_id}:log-group:*"]
    }
  }
}

module "data_key" {
  count  = var.enable_encryption ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/security/kms?ref=${{ values.moduleRef }}"

  alias                   = "${local.name_prefix}-data"
  description             = "Encrypts the stores of the ${local.name_prefix} data platform"
  policy                  = data.aws_iam_policy_document.data_key[0].json
  deletion_window_in_days = local.is_production ? 30 : 7
}

data "aws_iam_policy_document" "use_data_key" {
  count = var.enable_encryption ? 1 : 0

  statement {
    sid = "UseDataKey"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey",
    ]
    resources = [local.kms_key_arn]
  }
}

resource "aws_iam_policy" "use_data_key" {
  count = var.enable_encryption ? 1 : 0

  name        = "${local.name_prefix}-use-data-key"
  description = "Use of the data platform's KMS key"
  policy      = data.aws_iam_policy_document.use_data_key[0].json
}

# -----------------------------------------------------------------------------
# IAM roles: one per component, created only when the component exists. Each
# component attaches its own permissions to its role.
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "datazone_assume" {
  count = var.enable_data_lineage ? 1 : 0

  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["datazone.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }

    condition {
      test     = "ForAllValues:StringLike"
      variable = "aws:TagKeys"
      values   = ["datazone*"]
    }
  }
}

locals {
  role_definitions = {
    crawler = {
      enabled            = local.crawls_lake
      description        = "Glue crawlers that catalogue the data lake"
      services           = ["glue.amazonaws.com"]
      principals         = []
      assume_role_policy = null
      managed_policies   = ["${local.managed_policies}/service-role/AWSGlueServiceRole"]
    }
    etl = {
      enabled            = var.enable_etl_pipelines
      description        = "ETL jobs that move data from zone to zone"
      services           = [local.etl_native ? "glue.amazonaws.com" : "emr-serverless.amazonaws.com"]
      principals         = []
      assume_role_policy = null
      managed_policies   = local.etl_native ? ["${local.managed_policies}/service-role/AWSGlueServiceRole"] : []
    }
    warehouse = {
      enabled            = var.enable_data_warehouse && var.enable_data_lake
      description        = "Redshift queries on the curated zone of the data lake"
      services           = ["redshift.amazonaws.com"]
      principals         = []
      assume_role_policy = null
      managed_policies   = []
    }
    pipeline = {
      enabled            = local.pipeline_enabled
      description        = "Step Functions state machine that runs the data pipeline"
      services           = ["states.amazonaws.com"]
      principals         = []
      assume_role_policy = null
      managed_policies   = []
    }
    firehose = {
      enabled            = local.delivers_stream_to_lake
      description        = "Firehose delivery of the event stream to the raw zone"
      services           = ["firehose.amazonaws.com"]
      principals         = []
      assume_role_policy = null
      managed_policies   = []
    }
    bi = {
      enabled            = var.enable_bi_tools
      description        = "BI tools that query the data lake through Athena"
      services           = ["quicksight.amazonaws.com"]
      principals         = var.bi_trusted_principal_arns
      assume_role_policy = null
      managed_policies   = []
    }
    ml = {
      enabled            = var.enable_ml_platform
      description        = "Execution role of the SageMaker domain"
      services           = ["sagemaker.amazonaws.com"]
      principals         = []
      assume_role_policy = null
      managed_policies   = ["${local.managed_policies}/AmazonSageMakerFullAccess"]
    }
    lakeformation = {
      enabled            = var.enable_access_control && var.enable_data_lake
      description        = "Lake Formation access to the registered data lake buckets"
      services           = ["lakeformation.amazonaws.com"]
      principals         = []
      assume_role_policy = null
      managed_policies   = []
    }
    datazone = {
      enabled            = var.enable_data_lineage
      description        = "Execution role of the DataZone domain that stores data lineage"
      services           = []
      principals         = []
      assume_role_policy = one(data.aws_iam_policy_document.datazone_assume[*].json)
      managed_policies   = ["${local.managed_policies}/service-role/AmazonDataZoneDomainExecutionRolePolicy"]
    }
  }

  roles = { for key, role in local.role_definitions : key => role if role.enabled }
}

module "role" {
  for_each = local.roles
  source   = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/core/iam-role?ref=${{ values.moduleRef }}"

  name                = "${local.name_prefix}-${each.key}"
  description         = each.value.description
  assume_role_policy  = each.value.assume_role_policy
  trusted_services    = each.value.services
  trusted_roles       = each.value.principals
  managed_policy_arns = each.value.managed_policies
}

resource "aws_iam_role_policy_attachment" "use_data_key" {
  for_each = var.enable_encryption ? local.roles : {}

  role       = module.role[each.key].role_name
  policy_arn = aws_iam_policy.use_data_key[0].arn
}

# -----------------------------------------------------------------------------
# Network: private subnets that reach Amazon S3 through the gateway endpoint of
# the VPC. Only Spark jobs that report lineage need other endpoints; for them
# the VPC also gets public subnets with a NAT gateway.
# -----------------------------------------------------------------------------

#trivy:ignore:AVD-AWS-0164 Public subnets exist only with etl_engine = spark and data lineage, and hold nothing but the NAT gateways.
module "vpc" {
  count  = local.needs_network ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/network/vpc?ref=${{ values.moduleRef }}"

  name        = local.name_prefix
  environment = var.environment
  vpc_cidr    = var.vpc_cidr

  private_subnet_cidrs  = [for index in range(3) : cidrsubnet(var.vpc_cidr, 4, index)]
  public_subnet_cidrs   = local.etl_in_vpc ? [for index in range(3) : cidrsubnet(var.vpc_cidr, 4, index + 4)] : []
  database_subnet_cidrs = []

  enable_nat_gateway = local.etl_in_vpc
  single_nat_gateway = !local.is_production
}

# -----------------------------------------------------------------------------
# Artifacts bucket: job scripts, job logs, temporary files and query results.
# -----------------------------------------------------------------------------

module "artifacts" {
  count  = local.needs_artifacts ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/storage/s3?ref=${{ values.moduleRef }}"

  name          = "${var.project_name}-artifacts"
  environment   = var.environment
  force_destroy = !local.is_production

  encryption_type = var.enable_encryption ? "aws:kms" : "AES256"
  kms_key_arn     = local.kms_key_arn

  lifecycle_rules = [
    {
      id                                 = "expire-query-results"
      prefix                             = "athena-results/"
      expiration_days                    = 30
      noncurrent_version_expiration_days = 7
    },
    {
      id                                 = "expire-temporary-files"
      prefix                             = "tmp/"
      expiration_days                    = 7
      noncurrent_version_expiration_days = 7
    },
  ]
}

locals {
  artifacts_bucket = one(module.artifacts[*].bucket_name)
  artifacts_arn    = one(module.artifacts[*].bucket_arn)
}
