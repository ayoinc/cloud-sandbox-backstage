#!/bin/bash
set -e

echo "Provisioning ${{ values.name }}..."

# Update system
apt-get update -y

{%- if values.install_docker %}
# Install Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker vagrant
{%- endif %}

{%- if values.install_k3s %}
# Install K3s
curl -sfL https://get.k3s.io | sh -
{%- endif %}

echo "Provisioning complete!"
