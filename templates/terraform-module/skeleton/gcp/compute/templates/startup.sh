#!/bin/bash
# -----------------------------------------------------------------------------
# GCP Compute Instance Startup Script
# Project: ${project_id}
# Environment: ${environment}
# Region: ${region}
# -----------------------------------------------------------------------------

set -euo pipefail

# Log startup script execution
exec > >(tee -a /var/log/startup-script.log) 2>&1
echo "=== Startup script started at $(date) ==="
echo "Project: ${project_id}"
echo "Environment: ${environment}"
echo "Region: ${region}"

# -----------------------------------------------------------------------------
# System Updates
# -----------------------------------------------------------------------------

echo "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# -----------------------------------------------------------------------------
# Install Essential Packages
# -----------------------------------------------------------------------------

echo "Installing essential packages..."
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  jq \
  wget \
  git \
  htop \
  vim \
  unzip \
  software-properties-common

# -----------------------------------------------------------------------------
# Install and Configure Google Cloud Ops Agent
# -----------------------------------------------------------------------------

echo "Installing Google Cloud Ops Agent..."
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

# Configure Ops Agent
cat > /etc/google-cloud-ops-agent/config.yaml <<'EOF'
logging:
  receivers:
    syslog:
      type: files
      include_paths:
        - /var/log/messages
        - /var/log/syslog
        - /var/log/auth.log
    app_logs:
      type: files
      include_paths:
        - /var/log/app/*.log
  service:
    pipelines:
      default_pipeline:
        receivers: [syslog, app_logs]

metrics:
  receivers:
    hostmetrics:
      type: hostmetrics
      collection_interval: 60s
  processors:
    metrics_filter:
      type: exclude_metrics
      metrics_pattern: []
  service:
    pipelines:
      default_pipeline:
        receivers: [hostmetrics]
        processors: [metrics_filter]
EOF

# Restart Ops Agent
systemctl restart google-cloud-ops-agent

# -----------------------------------------------------------------------------
# Configure System Settings
# -----------------------------------------------------------------------------

echo "Configuring system settings..."

# Set timezone
timedatectl set-timezone UTC

# Configure hostname
INSTANCE_NAME=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/name" -H "Metadata-Flavor: Google")
ZONE=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google" | cut -d'/' -f4)
hostnamectl set-hostname "$INSTANCE_NAME"

# Add hostname to /etc/hosts
echo "127.0.0.1 $INSTANCE_NAME" >> /etc/hosts

# Configure sysctl for performance
cat >> /etc/sysctl.conf <<'EOF'
# Network performance tuning
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 30000
net.ipv4.tcp_max_syn_backlog = 8096
net.ipv4.tcp_slow_start_after_idle = 0

# File descriptor limits
fs.file-max = 65535
EOF

sysctl -p

# Configure file descriptor limits
cat >> /etc/security/limits.conf <<'EOF'
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF

# -----------------------------------------------------------------------------
# Create Application User
# -----------------------------------------------------------------------------

echo "Creating application user..."
useradd -r -m -s /bin/bash app || true
mkdir -p /home/app/logs
chown -R app:app /home/app

# Create application log directory
mkdir -p /var/log/app
chown -R app:app /var/log/app

# -----------------------------------------------------------------------------
# Setup Application Directory
# -----------------------------------------------------------------------------

echo "Setting up application directory..."
mkdir -p /opt/app/{bin,config,data}
chown -R app:app /opt/app

# Create environment file
cat > /opt/app/config/environment <<EOF
PROJECT_ID=${project_id}
ENVIRONMENT=${environment}
REGION=${region}
INSTANCE_NAME=$INSTANCE_NAME
ZONE=$ZONE
EOF

chown app:app /opt/app/config/environment

# -----------------------------------------------------------------------------
# Configure Health Check Endpoint
# -----------------------------------------------------------------------------

echo "Configuring health check endpoint..."

# Install nginx for health checks (optional - can be replaced with application server)
apt-get install -y nginx

# Configure nginx health check endpoint
cat > /etc/nginx/sites-available/health <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    location / {
        # Proxy to application or return default response
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
EOF

ln -sf /etc/nginx/sites-available/health /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx
systemctl enable nginx

# -----------------------------------------------------------------------------
# Install Docker (Optional)
# -----------------------------------------------------------------------------

if [ "${environment}" = "dev" ] || [ "${environment}" = "staging" ]; then
    echo "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add app user to docker group
    usermod -aG docker app
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
fi

# -----------------------------------------------------------------------------
# Format and Mount Data Disk (if attached)
# -----------------------------------------------------------------------------

DATA_DISK="/dev/disk/by-id/google-data-disk"
if [ -e "$DATA_DISK" ]; then
    echo "Configuring data disk..."
    
    # Check if disk is already formatted
    if ! blkid "$DATA_DISK" > /dev/null 2>&1; then
        echo "Formatting data disk..."
        mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard "$DATA_DISK"
    fi
    
    # Mount data disk
    mkdir -p /mnt/data
    mount -o discard,defaults "$DATA_DISK" /mnt/data
    
    # Add to fstab for persistence
    echo "$DATA_DISK /mnt/data ext4 discard,defaults,nofail 0 2" >> /etc/fstab
    
    # Set ownership
    chown -R app:app /mnt/data
fi

# -----------------------------------------------------------------------------
# Security Hardening
# -----------------------------------------------------------------------------

echo "Applying security hardening..."

# Disable root SSH login
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Enable and configure UFW (if not using GCP firewall exclusively)
# ufw --force enable
# ufw default deny incoming
# ufw default allow outgoing
# ufw allow 22/tcp
# ufw allow 80/tcp
# ufw allow 443/tcp

# Configure automatic security updates
apt-get install -y unattended-upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "$${distro_id}:$${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------

echo "Cleaning up..."
apt-get autoremove -y
apt-get clean

# -----------------------------------------------------------------------------
# Signal Completion
# -----------------------------------------------------------------------------

echo "=== Startup script completed at $(date) ==="

# Create startup completion marker
touch /var/log/startup-script-complete

# Log instance metadata
echo "Instance: $INSTANCE_NAME"
echo "Zone: $ZONE"
echo "Project: ${project_id}"
echo "Environment: ${environment}"
