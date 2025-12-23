# Overview

Welcome to the operational runbook for ${{ values.serviceName }}.

## What is a Runbook?

A runbook is a documented procedure for handling operational tasks and incidents. Good runbooks:

- Provide step-by-step instructions
- Include commands that can be copy-pasted
- Explain what to look for at each step
- Include escalation paths
- Are regularly tested and updated

## Runbook Structure

Each runbook follows this structure:

1. **Summary**: What the runbook addresses
2. **Symptoms**: How to identify the issue
3. **Impact**: Who/what is affected
4. **Steps**: Detailed resolution steps
5. **Verification**: How to confirm the issue is resolved
6. **Escalation**: When and how to escalate

## Key Dashboards

| Dashboard | Purpose | Link |
|-----------|---------|------|
| Service Health | Overall service status | [Link]() |
| Infrastructure | Server/container metrics | [Link]() |
| Logs | Centralized logging | [Link]() |
| Alerts | Alert history | [Link]() |

## Access Requirements

To use these runbooks, you need:

- [ ] VPN access to production network
- [ ] SSH access to bastion hosts
- [ ] Read access to monitoring dashboards
- [ ] Access to ${{ values.oncallTool }}

## Getting Help

If you're stuck:

1. Check the #sre-support Slack channel
2. Page the secondary on-call
3. Escalate through ${{ values.oncallTool }}
