# Values chosen in the portal when this repository was created.

project_name   = "${{ values.projectName }}"
environment    = "${{ values.environment }}"
gcp_project_id = "${{ values.gcpProjectId }}"
region         = "${{ values.region }}"
vpc_cidr       = "${{ values.vpcCidr }}"

compute_type = "${{ values.computeType }}"
{%- if values.computeType != 'gke-autopilot' %}

machine_type = "${{ values.machineType }}"
min_nodes    = ${{ values.minNodes }}
max_nodes    = ${{ values.maxNodes }}
{%- endif %}

database_engine   = "${{ values.databaseEngine }}"
database_tier     = "${{ values.databaseTier }}"
high_availability = ${{ values.highAvailability | dump }}

enable_cloud_armor = ${{ values.enableCloudArmor | dump }}
enable_cloud_cdn   = ${{ values.enableCloudCdn | dump }}
