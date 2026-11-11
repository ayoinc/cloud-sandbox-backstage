# AWS managed rule groups in front of the stage. With rate limiting on, a
# rate-based rule blocks a client address that exceeds requests_per_second
# averaged over WAF's five-minute window.
module "waf" {
  count  = var.enable_waf ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/security/waf?ref=83f9ff7222d2731d5cc0da4ab1fc1f7c46da3693"

  project_name = var.api_name
  environment  = local.stage_name
  name         = "waf"
  scope        = "REGIONAL"

  rate_limit_rules = var.enable_rate_limiting ? [{
    name     = "per-client-rate-limit"
    priority = 1
    limit    = var.requests_per_second * 300
    action   = "block"
  }] : []

  tags = local.tags
}

resource "aws_wafv2_web_acl_association" "api" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_api_gateway_stage.this.arn
  web_acl_arn  = module.waf[0].web_acl_arn
}
