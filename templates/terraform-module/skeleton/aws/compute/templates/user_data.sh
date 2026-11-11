#!/bin/bash
# Bootstraps an instance of ${name_prefix}: installs the CloudWatch agent with
# the configuration rendered by Terraform and creates the application account.
set -euo pipefail

dnf install -y amazon-cloudwatch-agent

install -d -m 0755 /opt/aws/amazon-cloudwatch-agent/etc
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWAGENT'
${cloudwatch_agent_config}
CWAGENT

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# The hostname carries the instance ID, read through IMDSv2.
token=$(curl -sf -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 300" http://169.254.169.254/latest/api/token)
instance_id=$(curl -sf -H "X-aws-ec2-metadata-token: $token" http://169.254.169.254/latest/meta-data/instance-id)
hostnamectl set-hostname "${name_prefix}-$instance_id"

# Unprivileged account that runs the application.
id app >/dev/null 2>&1 || useradd --system --create-home --shell /sbin/nologin app
