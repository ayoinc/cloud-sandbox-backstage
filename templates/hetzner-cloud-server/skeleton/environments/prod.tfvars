# =============================================================================
# Production Environment Configuration
# =============================================================================
# Two servers behind a load balancer, daily backups and deletion protection.
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "prod"
location    = "${{ values.location }}"
owner       = "${{ values.owner }}"

{% set fromForm = values.envName == 'prod' -%}
# Servers{% if fromForm %} (sized from the template form){% endif %}
server_count   = ${{ values.serverCount if fromForm else 2 }}
server_type    = "${{ values.serverType }}"
image          = "${{ values.image }}"
enable_backups = true
protection     = true

# Private network (one range per environment)
network_cidr = "10.30.0.0/24"

# Load balancer
load_balancer      = ${{ 'true' if values.loadBalancer and fromForm else 'true' }}
load_balancer_type = "lb11"

# Access
ssh_key_names     = ["${{ values.sshKeyName }}"]
admin_user        = "ops"
ssh_allowed_cidrs = [{% if values.sshSourceCidr %}"${{ values.sshSourceCidr }}"{% endif %}]
allow_web         = ${{ 'true' if values.allowWeb else 'false' }}
