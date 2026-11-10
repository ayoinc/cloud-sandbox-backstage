# -----------------------------------------------------------------------------
# SageMaker: execution role and model registry
# -----------------------------------------------------------------------------
resource "aws_iam_role" "sagemaker" {
  count = var.enable_ai_ml ? 1 : 0

  name = "${local.name}-sagemaker"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "sagemaker.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "sagemaker" {
  count = var.enable_ai_ml ? 1 : 0

  name = "${local.name}-sagemaker"
  role = aws_iam_role.sagemaker[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Logs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${local.partition}:logs:${var.region}:${local.account_id}:log-group:/aws/sagemaker/*"
      },
      {
        Sid    = "Encryption"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.main.arn
      }
    ]
  })
}

resource "aws_sagemaker_model_package_group" "main" {
  count = var.enable_ai_ml ? 1 : 0

  model_package_group_name        = local.name
  model_package_group_description = "Models of the ${local.name} stack"
}
