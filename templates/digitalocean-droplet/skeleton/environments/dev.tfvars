# =============================================================================
# Development Environment Configuration
# =============================================================================
# One small Droplet without backups.
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "dev"
region      = "${{ values.region }}"
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

{% set fromForm = values.envName == 'dev' -%}
# Droplets{% if fromForm %} (sized from the template form){% endif %}
droplet_count  = ${{ values.dropletCount if fromForm else 1 }}
size           = "${{ values.size if fromForm else 's-1vcpu-2gb' }}"
image          = "${{ values.image }}"
enable_backups = false
reserved_ip    = ${{ 'true' if values.reservedIp and fromForm else 'false' }}

# Network (one range per environment so the VPCs can be peered)
vpc_cidr = "10.210.0.0/24"

# Access
ssh_key_names     = ["${{ values.sshKeyName }}"]
admin_user        = "ops"
ssh_allowed_cidrs = [{% if values.sshSourceCidr %}"${{ values.sshSourceCidr }}"{% endif %}]
allow_web         = ${{ 'true' if values.allowWeb else 'false' }}
