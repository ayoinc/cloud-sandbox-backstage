{%- set dnf = values.base_os == "rhel-9" or values.base_os == "amazon-linux-2023" -%}
#!/usr/bin/env bash
# Installs the software baked into the ${{ values.name }} image. Packer runs
# this as root on the temporary build machine.
set -euo pipefail
{%- if dnf %}

# --allowerasing lets full packages replace the minimal variants some base
# images ship (curl-minimal on Amazon Linux 2023).
dnf install -y --allowerasing{% for pkg in values.custom_packages %} ${{ pkg }}{% endfor %}{% if not values.custom_packages | length %} ca-certificates{% endif %}
{%- if values.install_docker %}

{%- if values.base_os == "amazon-linux-2023" %}
dnf install -y docker
{%- else %}
dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
{%- endif %}
systemctl enable docker
{%- endif %}
{%- if values.install_ansible %}

dnf install -y python3-pip
python3 -m pip install ansible
{%- endif %}

dnf clean all
{%- else %}

export DEBIAN_FRONTEND=noninteractive

# Cloud images finish their own first-boot setup in the background; wait for
# it so that apt is not locked.
if command -v cloud-init >/dev/null 2>&1; then
  cloud-init status --wait || true
fi

apt-get update -y
apt-get install -y ca-certificates{% for pkg in values.custom_packages %} ${{ pkg }}{% endfor %}
{%- if values.install_docker %}

apt-get install -y curl
curl -fsSL https://get.docker.com | sh
systemctl enable docker
{%- endif %}
{%- if values.install_ansible %}

apt-get install -y ansible
{%- endif %}

apt-get clean
rm -rf /var/lib/apt/lists/*
{%- endif %}
