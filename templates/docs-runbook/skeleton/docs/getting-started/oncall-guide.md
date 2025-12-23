# On-Call Guide

This guide helps you prepare for and execute on-call responsibilities.

## Before Your Shift

### Preparation Checklist

- [ ] Review recent incidents in the last 7 days
- [ ] Check for any ongoing maintenance windows
- [ ] Verify access to all required systems
- [ ] Test ${{ values.oncallTool }} notifications
- [ ] Review handoff notes from previous on-call

### Required Access

Ensure you have access to:

| System | Purpose | How to Get Access |
|--------|---------|-------------------|
| ${{ values.oncallTool }} | Alerts | Request from team lead |
| Monitoring | Dashboards | Self-service |
| Logging | Log analysis | Self-service |
| SSH | Server access | Request from security |

## During Your Shift

### When an Alert Fires

1. **Acknowledge** the alert in ${{ values.oncallTool }}
2. **Assess** the severity and impact
3. **Communicate** in #incidents channel
4. **Investigate** using relevant runbook
5. **Resolve** or **Escalate** as needed
6. **Document** actions taken

### Severity Levels

| Level | Description | Response Time |
|-------|-------------|---------------|
| SEV1 | Complete outage | Immediate |
| SEV2 | Major degradation | 15 minutes |
| SEV3 | Minor impact | 1 hour |
| SEV4 | Informational | Next business day |

### Communication Templates

**Incident Start:**
```
🔴 Incident Started
Service: ${{ values.serviceName }}
Impact: [Description]
Status: Investigating
```

**Incident Update:**
```
🟡 Incident Update
Service: ${{ values.serviceName }}
Status: [Current status]
ETA: [If known]
```

**Incident Resolved:**
```
🟢 Incident Resolved
Service: ${{ values.serviceName }}
Duration: [X minutes/hours]
RCA: [Link to follow]
```

## Escalation

### When to Escalate

- You've spent 15+ minutes without progress
- Impact is increasing
- You need expertise you don't have
- Customer-facing impact exceeds SLA

### How to Escalate

1. Page the secondary on-call
2. If no response in 5 minutes, page team lead
3. For SEV1, page engineering manager

## After Your Shift

### Handoff Checklist

- [ ] Document any ongoing issues
- [ ] Note any alerts that need attention
- [ ] Update runbooks if you found gaps
- [ ] Brief the incoming on-call engineer

### Post-Incident

- Contribute to post-mortem within 48 hours
- Update runbooks with lessons learned
- Follow up on action items assigned to you
