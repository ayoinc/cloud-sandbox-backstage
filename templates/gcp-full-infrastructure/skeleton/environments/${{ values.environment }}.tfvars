# Values entered in the developer portal. Edit this file to change the
# ${{ values.environment }} environment.

project_name   = "${{ values.projectName }}"
component_name = "${{ values.componentName }}"
description    = "${{ values.description }}"
project_id     = "${{ values.gcpProjectId }}"
environment    = "${{ values.environment }}"
region         = "${{ values.region }}"

labels = { {% for key, value in values.tags %}"${{ key }}" = "${{ value }}", {% endfor %}"owner" = "${{ (values.owner | parseEntityRef).name }}" }

# Resource categories
enable_networking = ${{ values.enable_networking }}
enable_compute    = ${{ values.enable_compute }}
enable_containers = ${{ values.enable_containers }}
enable_storage    = ${{ values.enable_storage }}
enable_database   = ${{ values.enable_database }}
enable_security   = ${{ values.enable_security }}
enable_monitoring = ${{ values.enable_monitoring }}
enable_analytics  = ${{ values.enable_analytics }}
enable_ai_ml      = ${{ values.enable_ai_ml }}
enable_serverless = ${{ values.enable_serverless }}

# Networking
network_cidr = "${{ values.network_cidr }}"

subnets = [
{%- for subnet in values.subnet_configurations %}
  {
    name   = "${{ subnet.name }}"
    cidr   = "${{ subnet.cidr }}"
    region = "${{ subnet.region }}"
  },
{%- endfor %}
]

# Compute
machine_type   = "${{ values.machine_type }}"
boot_disk_size = ${{ values.boot_disk_size }}
boot_disk_type = "${{ values.boot_disk_type }}"

# Containers
gke_version            = "${{ values.gke_version }}"
gke_node_machine_type  = "${{ values.gke_node_machine_type }}"
gke_initial_node_count = ${{ values.gke_initial_node_count }}
gke_min_node_count     = ${{ values.gke_min_node_count }}
gke_max_node_count     = ${{ values.gke_max_node_count }}

# Zones of the GKE nodes. All zones of the region are used when empty.
gke_node_locations = [
{%- for zone in values.gke_node_locations %}
  "${{ zone }}",
{%- endfor %}
]

# Storage
storage_class     = "${{ values.storage_class }}"
enable_versioning = ${{ values.enable_versioning }}
enable_filestore  = ${{ values.enable_filestore }}

# Database
cloudsql_database_version = "${{ values.cloudsql_database_version }}"
cloudsql_tier             = "${{ values.cloudsql_tier }}"
cloudsql_disk_size        = ${{ values.cloudsql_disk_size }}
cloudsql_backup_retention = ${{ values.cloudsql_backup_retention }}
enable_firestore          = ${{ values.enable_firestore }}
enable_redis              = ${{ values.enable_redis }}
