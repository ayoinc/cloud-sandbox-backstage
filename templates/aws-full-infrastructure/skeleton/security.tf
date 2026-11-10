# -----------------------------------------------------------------------------
# Account-level security services for this region
# -----------------------------------------------------------------------------
resource "aws_guardduty_detector" "main" {
  # checkov:skip=CKV2_AWS_3: GuardDuty is enabled for this account and region; organisation-wide enrolment belongs to the organisation's management account
  count = var.enable_security ? 1 : 0

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

resource "aws_accessanalyzer_analyzer" "main" {
  count = var.enable_security ? 1 : 0

  analyzer_name = local.name
  type          = "ACCOUNT"
}

resource "aws_ebs_encryption_by_default" "main" {
  count = var.enable_security ? 1 : 0

  enabled = true
}
