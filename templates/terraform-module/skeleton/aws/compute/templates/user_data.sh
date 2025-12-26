#!/bin/bash
# -----------------------------------------------------------------------------
# EC2 User Data Script
# Project: ${project}
# Environment: ${environment}
# -----------------------------------------------------------------------------

set -euo pipefail

# Update system packages
dnf update -y

# Install essential packages
dnf install -y \
  amazon-cloudwatch-agent \
  aws-cli \
  jq \
  curl \
  wget \
  git \
  htop \
  vim

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/${project}/${environment}/system",
            "log_stream_name": "{instance_id}/messages"
          },
          {
            "file_path": "/var/log/secure",
            "log_group_name": "/${project}/${environment}/security",
            "log_stream_name": "{instance_id}/secure"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "${project}/${environment}",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch Agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Set hostname
hostnamectl set-hostname ${project}-${environment}-$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Create application user
useradd -r -s /bin/bash app || true

# Signal completion
echo "User data script completed successfully"
