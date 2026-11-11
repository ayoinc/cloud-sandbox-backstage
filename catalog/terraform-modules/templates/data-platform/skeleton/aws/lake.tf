# -----------------------------------------------------------------------------
# Data lake: one S3 bucket per zone. data_lake_storage_class decides how
# objects move to cheaper storage classes as they age.
# -----------------------------------------------------------------------------

locals {
  lake_zones = toset(var.enable_data_lake ? local.zones : [])

  # Every class used here keeps objects readable without a restore, so Athena,
  # Glue, EMR and Redshift can still query aged data.
  lake_transitions = {
    standard = []
    infrequent = [
      { days = 30, storage_class = "STANDARD_IA" },
    ]
    archive = [
      { days = 30, storage_class = "STANDARD_IA" },
      { days = 90, storage_class = "GLACIER_IR" },
    ]
  }
}

module "lake" {
  for_each = local.lake_zones
  source   = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/storage/s3?ref=${{ values.moduleRef }}"

  name          = "${var.project_name}-${each.key}"
  environment   = var.environment
  force_destroy = !local.is_production

  encryption_type = var.enable_encryption ? "aws:kms" : "AES256"
  kms_key_arn     = local.kms_key_arn

  lifecycle_rules = [
    {
      id                                 = "storage-class-${var.data_lake_storage_class}"
      noncurrent_version_expiration_days = 90
      transition                         = local.lake_transitions[var.data_lake_storage_class]
    },
  ]
}

locals {
  lake_bucket_arns = [for zone in local.zones : module.lake[zone].bucket_arn if var.enable_data_lake]

  # Where the ETL jobs read and write each zone. Without the data lake they
  # work in a staging area of the artifacts bucket.
  zone_uris = {
    for zone in local.zones : zone => (
      var.enable_data_lake ? "s3://${module.lake[zone].bucket_name}/" : "s3://${local.artifacts_bucket}/zones/${zone}/"
    ) if var.enable_data_lake || var.enable_etl_pipelines
  }
}
