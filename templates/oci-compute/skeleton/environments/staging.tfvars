# =============================================================================
# Staging Environment Configuration
# =============================================================================
# Production-like size.
# The compartment is not set here: the pipeline passes it from a repository
# secret (TF_VAR_compartment_ocid).
# =============================================================================

# Project Configuration
name        = "${{ values.name }}"
environment = "staging"
region      = "${{ values.region }}"
description = ${{ values.description | dump | replace('${', '$${') | replace('%{', '%%{') }}
owner       = "${{ values.owner }}"

{% set fromForm = values.envName == 'staging' -%}
# Instance{% if fromForm %} (sized from the template form){% endif %}
shape            = "${{ values.shape }}"
ocpus            = ${{ values.ocpus if fromForm else 2 }}
memory_gbs       = ${{ values.memoryGb if fromForm else 12 }}
operating_system = "${{ values.operatingSystem }}"
boot_volume_gbs  = 50

# Network (one range per environment so the VCNs can be peered)
vcn_cidr         = "10.41.0.0/16"
assign_public_ip = ${{ 'true' if values.assignPublicIp else 'false' }}

# Access
ssh_public_key    = "${{ values.sshPublicKey }}"
ssh_allowed_cidrs = [{% if values.sshSourceCidr %}"${{ values.sshSourceCidr }}"{% endif %}]
allow_web         = false
