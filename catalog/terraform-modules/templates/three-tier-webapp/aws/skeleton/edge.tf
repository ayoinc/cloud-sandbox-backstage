# -----------------------------------------------------------------------------
# Edge: web application firewall on the load balancer and an optional
# CloudFront distribution in front of it.
# -----------------------------------------------------------------------------

module "waf" {
  count  = var.enable_waf ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/security/waf?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  environment  = var.environment
  name         = "web"
  scope        = "REGIONAL"

  rate_limit_rules = [
    {
      name     = "rate-limit"
      priority = 1
      limit    = var.waf_rate_limit
      action   = "block"
    }
  ]
}

resource "aws_wafv2_web_acl_association" "alb" {
  count = var.enable_waf ? 1 : 0

  resource_arn = module.alb.lb_arn
  web_acl_arn  = module.waf[0].web_acl_arn
}

module "cloudfront" {
  count  = var.enable_cloudfront ? 1 : 0
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/network/cloudfront?ref=${{ values.moduleRef }}"

  project_name = var.project_name
  environment  = var.environment

  # CloudFront connects to the origin over HTTPS and checks its certificate, so
  # origin_domain_name must be a name covered by certificate_arn.
  origin_domain_name  = coalesce(var.origin_domain_name, module.alb.lb_dns_name)
  origin_id           = "alb"
  origin_type         = "custom"
  default_root_object = ""

  allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  cached_methods  = ["GET", "HEAD"]
  default_ttl     = 0

  aliases         = var.cloudfront_aliases
  certificate_arn = var.cloudfront_certificate_arn
}
