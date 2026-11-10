# -----------------------------------------------------------------------------
# Streaming ingestion and data catalog
# -----------------------------------------------------------------------------
resource "aws_kinesis_stream" "main" {
  count = var.enable_analytics ? 1 : 0

  name             = local.name
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = aws_kms_key.main.arn

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

resource "aws_glue_catalog_database" "main" {
  count = var.enable_analytics ? 1 : 0

  name        = replace(local.name, "-", "_")
  description = "Data catalog of the ${local.name} stack"
}
