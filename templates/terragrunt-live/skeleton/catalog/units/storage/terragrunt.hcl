# Unit: private, encrypted log storage.
#
# Values:
#   name                Prefix of the resource names, for example ${{ values.name }}-dev.
#   foundation_path     Path of the foundation unit, relative to this unit.
#   log_retention_days  Days that log objects are kept.
{%- if values.cloud != 'azure' %}
#   force_destroy       Whether the storage may be destroyed while it holds objects.
{%- endif %}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/catalog/modules/storage"
}

# Outputs of the foundation unit. The mock values stand in before the
# foundation has been applied, so a first plan of the whole stack works.
dependency "foundation" {
  config_path = values.foundation_path

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
{%- if values.cloud == 'aws' %}
  mock_outputs = {
    kms_key_arn = "arn:aws:kms:${{ values.region }}:111111111111:key/00000000-0000-0000-0000-000000000000"
  }
}

inputs = {
  name               = values.name
  kms_key_arn        = dependency.foundation.outputs.kms_key_arn
  log_retention_days = values.log_retention_days
  force_destroy      = values.force_destroy
}
{%- elif values.cloud == 'azure' %}
  mock_outputs = {
    resource_group_name = "rg-mock"
  }
}

inputs = {
  name                = values.name
  resource_group_name = dependency.foundation.outputs.resource_group_name
  log_retention_days  = values.log_retention_days
}
{%- else %}
  mock_outputs = {
    kms_key_id = "projects/mock/locations/${{ values.region }}/keyRings/mock/cryptoKeys/logs"
  }
}

inputs = {
  name               = values.name
  kms_key_id         = dependency.foundation.outputs.kms_key_id
  log_retention_days = values.log_retention_days
  force_destroy      = values.force_destroy
}
{%- endif %}
