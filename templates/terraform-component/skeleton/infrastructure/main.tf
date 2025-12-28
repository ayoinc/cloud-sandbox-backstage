# Generate consistent naming using shared module
module "naming" {
  source = "../shared-modules/naming"

  provider      = "{{ .provider }}"
  project       = var.project_name
  environment   = var.environment
  component     = var.component_name
  resource_type = "main"
  region        = replace(var.region, " ", "")
  instance      = "001"
}

# Generate standardized tags using shared module
module "tagging" {
  source = "../shared-modules/tagging"

  project     = var.project_name
  environment = var.environment
  team        = var.business_unit
  cost_center = var.cost_center
  additional_tags = {
    ComponentType = "{{ .componentType }}"
    ApplicationId = var.application_id
  }
}

# Resource Group (for Azure) or equivalent
{{ if eq .provider "azure" }}
module "resource_group" {
  source = "../resources/resource-group"

  name     = module.naming.name
  location = var.region
  tags     = module.tagging.tags
}
{{ end }}

# Example resource modules (commented out, user chooses which to enable)
# {{- range $resource := .resources }}
# module "{{ $resource }}" {
#   source = "../resources/{{ $resource }}"
#   
#   {{- if eq $.provider "azure" }}
#   resource_group_name = {{ if $.createResourceGroup }}module.resource_group.name{{ else }}var.resource_group_name{{ end }}
#   location            = var.region
#   {{- end }}
#   
#   name   = "${module.naming.name}-{{ $resource }}-001"
#   tags   = module.tagging.tags
# }
# {{ end }}