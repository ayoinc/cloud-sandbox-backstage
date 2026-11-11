# =============================================================================
# Staging Environment Configuration
# =============================================================================
# Production-like sizes with a single control plane node.
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "staging"
region      = "${{ values.region }}"
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

# Cluster (minor version; the latest patch release is used)
kubernetes_version = "${{ values.kubernetesVersion }}"
ha_control_plane   = false
auto_upgrade       = true
maintenance_window = {
  day        = "saturday"
  start_time = "03:00"
}

# Addresses allowed to reach the Kubernetes API; empty leaves it open to
# authenticated clients from anywhere.
control_plane_allowed_cidrs = []

# Network (one range per environment so the VPCs can be peered)
vpc_cidr = "10.120.0.0/20"

{% set fromForm = values.envName == 'staging' -%}
# Default node pool{% if fromForm %} (sized from the template form){% endif %}
node_size = "${{ values.nodeSize if fromForm else 's-4vcpu-8gb' }}"
min_nodes = ${{ values.nodeCount if fromForm else 2 }}
max_nodes = ${{ ([values.nodeCount, values.maxNodeCount] | sort | last) if fromForm else 5 }}

additional_node_pools = {}

# Container registry (the registry of the account is shared by all environments)
registry_integration = ${{ 'false' if values.registry == 'none' else 'true' }}
create_registry      = ${{ 'true' if values.registry == 'create' and fromForm else 'false' }}
registry_tier        = "basic"
