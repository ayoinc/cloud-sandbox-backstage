# =============================================================================
# Production Environment Configuration
# =============================================================================
# Two Droplets with weekly backups and reserved IPs.
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "prod"
region      = "${{ values.region }}"
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

{% set fromForm = values.envName == 'prod' -%}
# Droplets{% if fromForm %} (sized from the template form){% endif %}
droplet_count  = ${{ values.dropletCount if fromForm else 2 }}
size           = "${{ values.size if fromForm else 's-2vcpu-4gb' }}"
image          = "${{ values.image }}"
enable_backups = true
reserved_ip    = ${{ 'true' if values.reservedIp and fromForm else 'true' }}

# Network (one range per environment so the VPCs can be peered)
vpc_cidr = "10.230.0.0/24"

# Access
ssh_key_names     = ["${{ values.sshKeyName }}"]
admin_user        = "ops"
ssh_allowed_cidrs = [{% if values.sshSourceCidr %}"${{ values.sshSourceCidr }}"{% endif %}]
allow_web         = ${{ 'true' if values.allowWeb else 'false' }}
