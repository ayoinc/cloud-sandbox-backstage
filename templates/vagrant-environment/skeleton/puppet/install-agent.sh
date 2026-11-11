#!/usr/bin/env bash
# Installs the Puppet agent that the Vagrant puppet provisioner runs.
set -euo pipefail

if command -v puppet >/dev/null 2>&1 || [ -x /opt/puppetlabs/bin/puppet ]; then
  exit 0
fi

if command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y puppet
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y epel-release || true
  dnf install -y puppet
else
  echo "Unsupported box: neither apt-get nor dnf is available" >&2
  exit 1
fi
