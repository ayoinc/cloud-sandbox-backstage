# The stack of this environment and region. `terragrunt stack generate` turns
# each unit block into a directory under .terragrunt-stack/; `terragrunt run
# --all` does so implicitly.

locals {
  env   = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  units = "${get_repo_root()}/catalog/units"
  name  = "${{ values.name }}-${local.env.environment}"
}

unit "foundation" {
  source = "${local.units}/foundation"
  path   = "foundation"

  values = {
    name = local.name
  }
}

unit "storage" {
  source = "${local.units}/storage"
  path   = "storage"

  values = {
    name               = local.name
    foundation_path    = "../foundation"
    log_retention_days = local.env.log_retention_days
{%- if values.cloud != 'azure' %}
    force_destroy      = local.env.force_destroy
{%- endif %}
  }
}
