locals {
  standard = merge(
    {
      Component     = var.component_name
      ComponentType = var.component_type
      Project       = var.project
      Environment   = var.environment
      BusinessUnit  = var.business_unit
      CostCenter    = var.cost_center
      Owner         = var.owner
      ManagedBy     = "terraform"
    },
    var.application_id != "" ? { ApplicationId = var.application_id } : {},
  )

  tags = merge(var.additional_tags, local.standard)

  # Google Cloud labels allow only lowercase letters, digits, hyphens and
  # underscores, and at most 63 characters.
  labels = {
    for key, value in local.tags :
    substr(replace(lower(replace(key, "/([a-z0-9])([A-Z])/", "$1-$2")), "/[^a-z0-9_-]/", "-"), 0, 63) =>
    substr(replace(lower(value), "/[^a-z0-9_-]/", "-"), 0, 63)
  }
}
