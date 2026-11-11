# =============================================================================
# Development Environment Configuration
# =============================================================================
# One server without backups; resources can be deleted freely.
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "dev"
location    = "${{ values.location }}"
owner       = "${{ values.owner }}"

{% set fromForm = values.envName == 'dev' -%}
# Servers{% if fromForm %} (sized from the template form){% endif %}
server_count   = ${{ values.serverCount if fromForm else 1 }}
server_type    = "${{ values.serverType }}"
image          = "${{ values.image }}"
enable_backups = false
protection     = false

# Private network (one range per environment)
network_cidr = "10.10.0.0/24"

# Load balancer
load_balancer      = ${{ 'true' if values.loadBalancer and fromForm else 'false' }}
load_balancer_type = "lb11"

# Access
ssh_key_names     = ["${{ values.sshKeyName }}"]
admin_user        = "ops"
ssh_allowed_cidrs = [{% if values.sshSourceCidr %}"${{ values.sshSourceCidr }}"{% endif %}]
allow_web         = ${{ 'true' if values.allowWeb else 'false' }}
