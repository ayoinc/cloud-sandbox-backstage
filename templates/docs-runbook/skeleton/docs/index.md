# ${{ values.name }}

${{ values.description }}

## Overview

This runbook provides comprehensive operational documentation for **${{ values.serviceName }}**, including incident response procedures, standard operating procedures, and on-call guidance. It serves as the primary reference for operators managing this service in production.

```d2
direction: right

title: {
  label: Runbook Documentation System
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

alert: Alert Triggered {
  shape: oval
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
}

oncall: On-Call Engineer {
  shape: person
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

runbook: Runbook System {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  incidents: Incident Runbooks {
    style.fill: "#FFCDD2"
    style.stroke: "#D32F2F"

    service_down: Service Down
    high_cpu: High CPU
    high_memory: High Memory
    db_issues: Database Issues
  }

  procedures: Standard Procedures {
    style.fill: "#C8E6C9"
    style.stroke: "#388E3C"

    deployment: Deployment
    rollback: Rollback
    scaling: Scaling
  }

  guides: Guides {
    style.fill: "#FFF9C4"
    style.stroke: "#FBC02D"

    oncall_guide: On-Call Guide
    escalation: Escalation
  }
}

resolution: Resolution {
  shape: oval
  style.fill: "#C8E6C9"
  style.stroke: "#388E3C"
}

alert -> oncall: "Pages"
oncall -> runbook: "Consults"
runbook -> resolution: "Resolves"
```

---

## Configuration Summary

| Setting | Value |
| --- | --- |
| Runbook Name | `${{ values.name }}` |
| Service Name | `${{ values.serviceName }}` |
| Owner | `${{ values.owner }}` |
| On-Call Tool | `${{ values.oncallTool }}` |
| Environments | {% for env in values.environment %}{{ env }}{% if not loop.last %}, {% endif %}{% endfor %} |
| Templates Included | `${{ values.includeTemplates }}` |

---

## Quick Links

| Category | Description | When to Use |
| --- | --- | --- |
| [Incidents](incidents/index.md) | Response procedures for common incidents | During active incidents |
| [Procedures](procedures/index.md) | Standard operational procedures | Routine operations |
| [On-Call Guide](getting-started/oncall-guide.md) | Guide for on-call engineers | Starting on-call rotation |
| [Templates](templates/index.md) | Runbook templates | Creating new runbooks |

---

## Service Overview

```d2
direction: down

title: {
  label: ${{ values.serviceName }} Service Architecture
  near: top-center
  shape: text
  style.font-size: 20
  style.bold: true
}

internet: Internet {
  shape: cloud
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
}

lb: Load Balancer {
  shape: hexagon
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

service: ${{ values.serviceName }} {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  pod1: Pod 1
  pod2: Pod 2
  pod3: Pod 3
}

dependencies: Dependencies {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"

  database: Database {
    shape: cylinder
  }

  cache: Cache {
    shape: cylinder
  }

  queue: Message Queue {
    shape: queue
  }
}

monitoring: Monitoring {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"

  metrics: Metrics
  logs: Logs
  traces: Traces
}

internet -> lb
lb -> service
service -> dependencies
service -> monitoring: "Observability"
```

### Service Information

| Property | Value |
| --- | --- |
| **Service** | ${{ values.serviceName }} |
| **Type** | Microservice / API / Worker |
| **SLO** | 99.9% availability |
| **Owner** | ${{ values.owner }} |

### Environments

{% for env in values.environment %}
#### {{ env | capitalize }}

| Property | Value |
| --- | --- |
| Environment | `{{ env }}` |
| Namespace | `${{ values.serviceName }}-{{ env }}` |
| Replicas | {% if env == "production" %}3{% elif env == "staging" %}2{% else %}1{% endif %} |
| Dashboard | [Grafana](https://grafana.example.com/d/${{ values.serviceName }}-{{ env }}) |

{% endfor %}

---

## Emergency Contacts

| Role | Contact | When to Contact |
| --- | --- | --- |
| On-Call Engineer | Check ${{ values.oncallTool }} | First point of contact |
| Team Lead | @team-lead | Escalation, critical decisions |
| Secondary On-Call | Check ${{ values.oncallTool }} | Primary unavailable |
| Engineering Manager | @eng-manager | Major incidents, customer escalations |
| Escalation Channel | #incident-response | SEV1/SEV2 incidents |

### On-Call Rotation

Access the current on-call schedule:

{% if values.oncallTool == "pagerduty" %}
```bash
# View current on-call
curl -H "Authorization: Token token=YOUR_API_KEY" \
  "https://api.pagerduty.com/oncalls?schedule_ids[]=YOUR_SCHEDULE_ID"

# Or visit: https://yourcompany.pagerduty.com/schedules
```
{% elif values.oncallTool == "opsgenie" %}
```bash
# View current on-call
curl -H "Authorization: GenieKey YOUR_API_KEY" \
  "https://api.opsgenie.com/v2/schedules/YOUR_SCHEDULE_ID/on-calls"

# Or visit: https://yourcompany.app.opsgenie.com/teams
```
{% elif values.oncallTool == "victorops" %}
```bash
# View current on-call in VictorOps dashboard
# https://portal.victorops.com/
```
{% else %}
Contact the team lead directly or check the team calendar.
{% endif %}

---

## How to Use This Runbook

### During an Incident

```d2
direction: right

alert: Alert {
  shape: oval
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
}

triage: Triage {
  style.fill: "#FFF9C4"
  style.stroke: "#FBC02D"
  label: "Identify Issue Type"
}

runbook: Find Runbook {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

execute: Execute Steps {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

resolve: Resolve {
  shape: oval
  style.fill: "#C8E6C9"
  style.stroke: "#388E3C"
}

escalate: Escalate {
  shape: diamond
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
}

alert -> triage -> runbook -> execute
execute -> resolve: "Success"
execute -> escalate: "Need Help"
escalate -> execute: "Continue"
```

1. **Acknowledge the alert** in ${{ values.oncallTool }}
2. **Identify the incident type** from the alert
3. **Navigate to [Incidents](incidents/index.md)** and find the relevant runbook
4. **Follow the steps** in order
5. **Communicate** in #incident-response
6. **Escalate if needed** following the escalation matrix
7. **Document** the incident after resolution

### For Routine Operations

1. Navigate to [Procedures](procedures/index.md)
2. Find the relevant procedure
3. Follow the documented steps
4. Verify success using the validation commands

### When Starting On-Call

1. Read the [On-Call Guide](getting-started/oncall-guide.md)
2. Verify access to all systems
3. Check recent incidents and ongoing issues
4. Review any active maintenance windows

---

## Incident Runbooks

### Incident Index

| Runbook | Alert Pattern | Severity | MTTR |
| --- | --- | --- | --- |
| [Service Down](incidents/service-down.md) | `ServiceDown`, `EndpointDown` | SEV1 | 15 min |
| [High CPU](incidents/high-cpu.md) | `HighCPUUsage` | SEV2 | 20 min |
| [High Memory](incidents/high-memory.md) | `HighMemoryUsage` | SEV2 | 20 min |
| [Database Issues](incidents/database-issues.md) | `DatabaseConnectionError` | SEV1 | 30 min |

### Severity Definitions

```d2
direction: right

sev1: SEV1 - Critical {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "Complete outage\n< 15 min response"
}

sev2: SEV2 - High {
  style.fill: "#FFE0B2"
  style.stroke: "#F57C00"
  label: "Degraded service\n< 30 min response"
}

sev3: SEV3 - Medium {
  style.fill: "#FFF9C4"
  style.stroke: "#FBC02D"
  label: "Minor impact\n< 4 hour response"
}

sev4: SEV4 - Low {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "No impact\nNext business day"
}
```

| Severity | Description | Response Time | Examples |
| --- | --- | --- | --- |
| **SEV1** | Complete service outage | < 15 minutes | Service down, data loss |
| **SEV2** | Degraded service | < 30 minutes | High latency, partial outage |
| **SEV3** | Minor impact | < 4 hours | Feature unavailable |
| **SEV4** | No user impact | Next business day | Monitoring gap |

### Incident Response Flow

```d2
direction: down

title: {
  label: Incident Response Lifecycle
  near: top-center
  shape: text
  style.font-size: 18
  style.bold: true
}

detect: Detection {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"

  alert: Alert Triggered
  report: User Report
}

respond: Response {
  style.fill: "#FFF9C4"
  style.stroke: "#FBC02D"

  ack: Acknowledge
  assess: Assess Impact
  communicate: Communicate
}

mitigate: Mitigation {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  diagnose: Diagnose
  fix: Apply Fix
  verify: Verify
}

resolve: Resolution {
  style.fill: "#C8E6C9"
  style.stroke: "#388E3C"

  close: Close Incident
  document: Document
  postmortem: Schedule Postmortem
}

detect -> respond
respond -> mitigate
mitigate -> resolve
```

---

## Standard Procedures

### Procedure Index

| Procedure | Description | Duration | Risk Level |
| --- | --- | --- | --- |
| [Deployment](procedures/deployment.md) | Deploy new version | 15-30 min | Medium |
| [Rollback](procedures/rollback.md) | Rollback to previous version | 5-10 min | Low |
| [Scaling](procedures/scaling.md) | Scale replicas up/down | 5 min | Low |

### Quick Commands

#### Health Check

```bash
# Kubernetes
kubectl get pods -l app=${{ values.serviceName }} -n production
kubectl describe deployment ${{ values.serviceName }} -n production

# Health endpoint
curl -f http://${{ values.serviceName }}.production.svc/health
```

#### View Logs

```bash
# Recent logs
kubectl logs -l app=${{ values.serviceName }} -n production --tail=100

# Follow logs
kubectl logs -l app=${{ values.serviceName }} -n production -f

# Logs from crashed container
kubectl logs -l app=${{ values.serviceName }} -n production --previous
```

#### Resource Status

```bash
# CPU and memory usage
kubectl top pods -l app=${{ values.serviceName }} -n production

# Resource quotas
kubectl describe resourcequota -n production
```

#### Quick Restart

```bash
# Restart deployment
kubectl rollout restart deployment/${{ values.serviceName }} -n production

# Watch rollout status
kubectl rollout status deployment/${{ values.serviceName }} -n production
```

---

## Monitoring & Observability

### Dashboards

| Dashboard | Purpose | Link |
| --- | --- | --- |
| Service Overview | General health metrics | [Grafana](https://grafana.example.com/d/${{ values.serviceName }}) |
| SLO Dashboard | Service level objectives | [Grafana](https://grafana.example.com/d/${{ values.serviceName }}-slo) |
| Error Rates | Error tracking | [Grafana](https://grafana.example.com/d/${{ values.serviceName }}-errors) |
| Latency | Response time metrics | [Grafana](https://grafana.example.com/d/${{ values.serviceName }}-latency) |

### Key Metrics

```d2
direction: right

requests: Requests/sec {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

latency: Latency (p99) {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

errors: Error Rate {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
}

saturation: Saturation {
  style.fill: "#FFF9C4"
  style.stroke: "#FBC02D"
}
```

| Metric | Target | Alert Threshold | Query |
| --- | --- | --- | --- |
| **Request Rate** | N/A | N/A (informational) | `rate(http_requests_total[5m])` |
| **Error Rate** | < 0.1% | > 1% | `rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])` |
| **Latency (p99)** | < 200ms | > 500ms | `histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))` |
| **CPU Usage** | < 70% | > 85% | `container_cpu_usage_seconds_total` |
| **Memory Usage** | < 80% | > 90% | `container_memory_usage_bytes` |

### Logs

```bash
# Application logs
kubectl logs -l app=${{ values.serviceName }} -n production

# Structured log query (if using centralized logging)
# Kibana: kubernetes.labels.app:${{ values.serviceName }} AND level:error
# Loki: {app="${{ values.serviceName }}"} |= "error"
```

### Traces

Access distributed traces for debugging:

| Tool | Query |
| --- | --- |
| Jaeger | `service=${{ values.serviceName }}` |
| Zipkin | `serviceName=${{ values.serviceName }}` |
| Tempo | `{resource.service.name="${{ values.serviceName }}"}` |

---

## Escalation Matrix

### When to Escalate

```d2
direction: down

start: Issue Detected {
  shape: oval
  style.fill: "#E3F2FD"
}

try_fix: Attempt Resolution {
  style.fill: "#E8F5E9"
}

check_time: > 15 min? {
  shape: diamond
  style.fill: "#FFF9C4"
}

check_severity: SEV1/SEV2? {
  shape: diamond
  style.fill: "#FFF9C4"
}

check_expertise: Need Expertise? {
  shape: diamond
  style.fill: "#FFF9C4"
}

escalate: Escalate {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
}

continue: Continue {
  style.fill: "#C8E6C9"
}

start -> try_fix
try_fix -> check_time
check_time -> escalate: "Yes"
check_time -> check_severity: "No"
check_severity -> escalate: "Yes"
check_severity -> check_expertise: "No"
check_expertise -> escalate: "Yes"
check_expertise -> continue: "No"
```

**Escalate immediately if:**

- Cannot identify root cause within 15 minutes
- Impact is broader than initially assessed
- Rollback is not possible or failed
- Data integrity concerns exist
- Customer-facing impact is confirmed
- You need expertise you don't have

### Escalation Path

| Level | Role | Contact | When |
| --- | --- | --- | --- |
| L1 | Primary On-Call | ${{ values.oncallTool }} | First responder |
| L2 | Secondary On-Call | ${{ values.oncallTool }} | L1 needs help |
| L3 | Team Lead | @team-lead | Major decisions |
| L4 | Engineering Manager | @eng-manager | Cross-team issues |
| L5 | Incident Commander | #incident-response | SEV1 incidents |

---

## Communication Templates

### Incident Start

```
🔴 Incident Started
Service: ${{ values.serviceName }}
Environment: [production/staging]
Impact: [Description of user impact]
Status: Investigating
On-Call: @[your-name]
```

### Incident Update

```
🟡 Incident Update
Service: ${{ values.serviceName }}
Status: Root cause identified - [brief description]
Action: [What's being done]
ETA: [Estimated time to resolution]
```

### Incident Resolved

```
🟢 Incident Resolved
Service: ${{ values.serviceName }}
Duration: [X minutes]
Root Cause: [Brief description]
Resolution: [What fixed it]
RCA: Will be posted within 48 hours
```

---

## Post-Incident Process

### Immediate Actions

- [ ] Close the incident in ${{ values.oncallTool }}
- [ ] Send resolution communication
- [ ] Create incident ticket if not exists
- [ ] Gather timeline and actions taken
- [ ] Identify follow-up actions

### Within 48 Hours

- [ ] Schedule postmortem meeting
- [ ] Draft incident timeline
- [ ] Collect relevant logs and metrics
- [ ] Identify contributing factors

### Postmortem Template

```markdown
# Postmortem: [Incident Title]

## Summary
Brief description of what happened.

## Impact
- Duration: X minutes
- Users affected: X
- Revenue impact: $X

## Timeline
| Time | Event |
| --- | --- |
| HH:MM | Alert triggered |
| HH:MM | On-call acknowledged |
| HH:MM | Root cause identified |
| HH:MM | Fix deployed |
| HH:MM | Resolution confirmed |

## Root Cause
Detailed explanation of what caused the incident.

## Contributing Factors
- Factor 1
- Factor 2

## Action Items
| Action | Owner | Due Date |
| --- | --- | --- |
| Action 1 | @owner | YYYY-MM-DD |
| Action 2 | @owner | YYYY-MM-DD |

## Lessons Learned
What went well, what didn't, what we'll do differently.
```

---

## Contributing

To add or update a runbook:

### Adding a New Runbook

1. **Create the file** in the appropriate directory:
   - Incident runbook: `docs/incidents/`
   - Procedure: `docs/procedures/`
   - Template: `docs/templates/`

2. **Use the template** from `docs/templates/`

3. **Required sections** for incident runbooks:
   - Summary
   - Symptoms
   - Impact
   - Immediate Actions
   - Investigation Steps
   - Resolution Steps
   - Verification
   - Communication
   - Escalation

4. **Test all commands** before submitting

5. **Submit a pull request** for review

### Runbook Quality Checklist

- [ ] All commands are tested and working
- [ ] Steps are numbered and clear
- [ ] Impact and severity are documented
- [ ] Verification steps included
- [ ] Communication templates provided
- [ ] Escalation criteria defined
- [ ] Related runbooks linked

---

## Related Templates

| Template | Description |
| --- | --- |
| [docs-adr](/docs/default/template/docs-adr) | Architecture Decision Records |
| [docs-project](/docs/default/template/docs-project) | Project documentation |
| [docs-d2-guide](/docs/default/template/docs-d2-guide) | D2 diagramming documentation |

---

## References

- [Google SRE Book](https://sre.google/sre-book/table-of-contents/)
- [Incident Management Best Practices](https://response.pagerduty.com/)
- [Postmortem Culture](https://sre.google/sre-book/postmortem-culture/)
- [Backstage TechDocs](https://backstage.io/docs/features/techdocs/)
{% if values.oncallTool == "pagerduty" %}
- [PagerDuty Documentation](https://support.pagerduty.com/)
{% elif values.oncallTool == "opsgenie" %}
- [OpsGenie Documentation](https://docs.opsgenie.com/)
{% elif values.oncallTool == "victorops" %}
- [VictorOps Documentation](https://help.victorops.com/)
{% endif %}

---

## Last Updated

This documentation is maintained by ${{ values.owner }}.

| Field | Value |
| --- | --- |
| Version | 1.0.0 |
| Last Updated | {{ date }} |
| Review Frequency | Monthly |
