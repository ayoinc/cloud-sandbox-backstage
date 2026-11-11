# Values chosen in the portal when this repository was created.

project_name       = "${{ values.projectName }}"
environment        = "${{ values.environment }}"
location           = "${{ values.location }}"
vnet_address_space = "${{ values.vnetAddressSpace }}"

compute_type = "${{ values.computeType }}"
vm_size      = "${{ values.vmSize }}"
min_nodes    = ${{ values.minNodes }}
max_nodes    = ${{ values.maxNodes }}

database_type = "${{ values.databaseType }}"
database_sku  = "${{ values.databaseSku }}"

enable_waf        = ${{ values.enableWaf | dump }}
enable_front_door = ${{ values.enableFrontDoor | dump }}
