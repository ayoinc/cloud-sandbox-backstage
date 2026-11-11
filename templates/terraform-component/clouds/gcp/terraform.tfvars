{%- set res = values.resources or [] -%}
# Values chosen when this component was created. Change them here and push to
# apply the change.
component_name = "${{ values.name }}"
component_type = "${{ values.componentType }}"
project_name   = "${{ values.projectName }}"
environment    = "${{ values.environment }}"

business_unit  = "${{ values.businessUnit }}"
cost_center    = "${{ values.costCenter }}"
application_id = "${{ values.applicationId }}"
owner          = "${{ values.owner }}"

company           = "${{ values.company }}"
naming_convention = "${{ values.namingConvention }}"

region = "${{ values.region }}"
{%- if values.secondaryRegion and "object-storage" in res %}

secondary_region = "${{ values.secondaryRegion }}"
{%- endif %}
{%- if values.autoShutdown and "virtual-machine" in res %}

auto_shutdown_schedule = "${{ values.autoShutdown }}"
{%- endif %}

create_resource_container = ${{ values.createResourceGroup | string | lower }}
