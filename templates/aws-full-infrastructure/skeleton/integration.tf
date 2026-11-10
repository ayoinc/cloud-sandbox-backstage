# -----------------------------------------------------------------------------
# Queue with a dead-letter queue
# -----------------------------------------------------------------------------
resource "aws_sqs_queue" "dead_letter" {
  count = var.enable_integration ? 1 : 0

  name                      = "${local.name}-dead-letter"
  message_retention_seconds = 1209600
  kms_master_key_id         = aws_kms_key.main.id
}

resource "aws_sqs_queue" "main" {
  count = var.enable_integration ? 1 : 0

  name              = local.name
  kms_master_key_id = aws_kms_key.main.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter[0].arn
    maxReceiveCount     = 5
  })
}

# -----------------------------------------------------------------------------
# Topic and event bus
# -----------------------------------------------------------------------------
resource "aws_sns_topic" "events" {
  count = var.enable_integration ? 1 : 0

  name              = "${local.name}-events"
  kms_master_key_id = aws_kms_key.main.id
}

resource "aws_cloudwatch_event_bus" "main" {
  count = var.enable_integration ? 1 : 0

  name = local.name
}
