# -----------------------------------------------------------------------------
# Streaming: a Kinesis data stream that keeps records for
# streaming_retention_hours. With the data lake, a Firehose stream delivers the
# records to the raw zone, where the ETL jobs pick them up as the dataset
# "streaming". Without the data lake only the data stream is created.
# -----------------------------------------------------------------------------

locals {
  # Kinesis Data Streams keeps records for 24 hours to 365 days.
  streaming_retention_hours = min(8760, max(24, floor(var.streaming_retention_hours)))

  delivers_stream_to_lake = var.enable_streaming && var.enable_data_lake
  delivery_stream_name    = "${local.name_prefix}-events-to-lake"
}

resource "aws_kinesis_stream" "events" {
  count = var.enable_streaming ? 1 : 0

  name             = "${local.name_prefix}-events"
  retention_period = local.streaming_retention_hours

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  encryption_type = "KMS"
  kms_key_id      = var.enable_encryption ? local.kms_key_arn : "alias/aws/kinesis"
}

resource "aws_cloudwatch_log_group" "delivery" {
  count = local.delivers_stream_to_lake ? 1 : 0

  name              = "/aws/kinesisfirehose/${local.delivery_stream_name}"
  retention_in_days = local.is_production ? 365 : 30
  kms_key_id        = local.kms_key_arn
}

resource "aws_cloudwatch_log_stream" "delivery" {
  count = local.delivers_stream_to_lake ? 1 : 0

  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.delivery[0].name
}

data "aws_iam_policy_document" "firehose" {
  count = local.delivers_stream_to_lake ? 1 : 0

  statement {
    sid = "ReadStream"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards",
    ]
    resources = [aws_kinesis_stream.events[0].arn]
  }

  statement {
    sid = "WriteRawZoneObjects"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${module.lake["raw"].bucket_arn}/*"]
  }

  statement {
    sid = "ListRawZone"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]
    resources = [module.lake["raw"].bucket_arn]
  }

  statement {
    sid       = "WriteDeliveryLogs"
    actions   = ["logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.delivery[0].arn}:log-stream:${aws_cloudwatch_log_stream.delivery[0].name}"]
  }
}

resource "aws_iam_role_policy" "firehose" {
  count = local.delivers_stream_to_lake ? 1 : 0

  name   = "delivery"
  role   = module.role["firehose"].role_name
  policy = data.aws_iam_policy_document.firehose[0].json
}

resource "aws_kinesis_firehose_delivery_stream" "lake" {
  count = local.delivers_stream_to_lake ? 1 : 0

  name        = local.delivery_stream_name
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.events[0].arn
    role_arn           = module.role["firehose"].role_arn
  }

  extended_s3_configuration {
    role_arn   = module.role["firehose"].role_arn
    bucket_arn = module.lake["raw"].bucket_arn

    # Objects land under streaming/<year>/<month>/<day>/<hour>/. Records that
    # cannot be delivered go to _errors/, which the ETL jobs and the crawler of
    # the raw zone leave out.
    prefix              = "streaming/"
    error_output_prefix = "_errors/streaming/!{firehose:error-output-type}/"

    buffering_size     = 64
    buffering_interval = 300
    compression_format = "GZIP"
    kms_key_arn        = local.kms_key_arn

    # One record per line, so the objects are valid JSON Lines files.
    processing_configuration {
      enabled = true

      processors {
        type = "AppendDelimiterToRecord"
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.delivery[0].name
      log_stream_name = aws_cloudwatch_log_stream.delivery[0].name
    }
  }

  depends_on = [
    aws_iam_role_policy.firehose,
    aws_iam_role_policy_attachment.use_data_key,
  ]
}
