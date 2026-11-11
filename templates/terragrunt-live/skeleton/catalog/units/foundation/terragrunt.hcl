# Unit: what the other units of a stack build on.
#
# Values:
#   name  Prefix of the resource names, for example ${{ values.name }}-dev.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/catalog/modules/foundation"
}

inputs = {
  name = values.name
}
