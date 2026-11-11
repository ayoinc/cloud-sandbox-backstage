#!/usr/bin/env bash
# Provisions the ${{ values.name }} VM. Runs as root on first `vagrant up` and
# on every `vagrant provision`, so each step is safe to repeat.
set -euo pipefail

echo "Provisioning ${{ values.name }}..."

if command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y curl ca-certificates git
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y curl ca-certificates git
else
  echo "Unsupported box: neither apt-get nor dnf is available" >&2
  exit 1
fi
{%- if values.install_docker %}

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi
usermod -aG docker vagrant
{%- endif %}
{%- if values.install_k3s %}

if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | sh -
fi
{%- endif %}

echo "Provisioning complete."
