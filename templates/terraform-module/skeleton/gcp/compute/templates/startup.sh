#!/bin/bash
# Installs the Ops Agent and an nginx site that answers on the application port.
# Rendered by Terraform: project ${project_name}, environment ${environment}.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# The script runs on every boot; the marker makes later boots a no-op.
marker=/var/lib/startup-script.done
if [ -f "$marker" ]; then
  exit 0
fi

apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl nginx

curl -fsSLo /tmp/add-google-cloud-ops-agent-repo.sh https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash /tmp/add-google-cloud-ops-agent-repo.sh --also-install
rm -f /tmp/add-google-cloud-ops-agent-repo.sh

cat > /etc/nginx/sites-available/default <<'NGINX'
server {
  listen ${app_port} default_server;
  server_name _;
  root /var/www/html;

  location = ${health_check_path} {
    access_log off;
    default_type text/plain;
    return 200 "ok\n";
  }
}
NGINX

echo "${project_name} (${environment}) on $(hostname)" > /var/www/html/index.html

nginx -t
systemctl enable nginx
systemctl restart nginx

touch "$marker"
