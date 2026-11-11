# A configuration that breaks the TFLint configuration (no version
# constraints, an untyped and undocumented variable, a camelCase name) and the
# custom Checkov checks (no owner tag, no lifecycle configuration).

variable "environment" {}

resource "aws_s3_bucket" "logBucket" {
  bucket = "sample-${var.environment}-logs"
}
