# PagerDuty Usage Guide

## SDK Installation

### Python SDK

```bash
pip install pdpyras
```

```python
from pdpyras import APISession, EventsAPISession
import os

# REST API client
api_token = os.environ['PD_API_TOKEN']
session = APISession(api_token)

# Events API client (for sending alerts)
routing_key = os.environ['PD_ROUTING_KEY']
events_session = EventsAPISession(routing_key)
```

### Node.js SDK

```bash
npm install @pagerduty/pdjs
```

```javascript
import { api, event } from '@pagerduty/pdjs';

// REST API client
const pdApi = api({ token: process.env.PD_API_TOKEN });

// Events API client
const pdEvents = event({ routingKey: process.env.PD_ROUTING_KEY });
```

### Go SDK

```bash
go get github.com/PagerDuty/go-pagerduty
```

```go
package main

import (
    "context"
    "os"
    "github.com/PagerDuty/go-pagerduty"
)

func main() {
    client := pagerduty.NewClient(os.Getenv("PD_API_TOKEN"))

    // Create incident
    ctx := context.Background()
    opts := pagerduty.CreateIncidentOptions{
        Type:    "incident",
        Title:   "Server unreachable",
        Service: &pagerduty.APIReference{
            ID:   "PXXXXXX",
            Type: "service_reference",
        },
    }
    incident, err := client.CreateIncidentWithContext(ctx, "PXXXXXX", &opts)
}
```

## Python Examples

### Send Alerts

```python
from pdpyras import EventsAPISession
import os

routing_key = os.environ['PD_ROUTING_KEY']
events = EventsAPISession(routing_key)

# Trigger an alert
dedup_key = events.trigger(
    summary="High CPU usage on web-server-01",
    source="monitoring-system",
    severity="critical",
    custom_details={
        "cpu_percent": 98.5,
        "memory_percent": 76.2,
        "disk_percent": 45.0,
        "hostname": "web-server-01",
        "datacenter": "us-east-1"
    }
)
print(f"Alert triggered with dedup_key: {dedup_key}")

# Acknowledge the alert
events.acknowledge(dedup_key)

# Resolve the alert
events.resolve(dedup_key)
```

### Manage Incidents

```python
from pdpyras import APISession
import os

session = APISession(os.environ['PD_API_TOKEN'])

# List open incidents
incidents = session.list_all(
    'incidents',
    params={
        'statuses[]': ['triggered', 'acknowledged'],
        'sort_by': 'created_at:desc'
    }
)

for incident in incidents:
    print(f"[{incident['status']}] {incident['title']}")
    print(f"  Created: {incident['created_at']}")
    print(f"  Service: {incident['service']['summary']}")
    print(f"  URL: {incident['html_url']}")
    print()

# Get specific incident
incident = session.rget(f"/incidents/Q1XXXXXX")

# Update incident (acknowledge)
session.rput(
    f"/incidents/{incident['id']}",
    json={
        'incident': {
            'type': 'incident_reference',
            'status': 'acknowledged'
        }
    }
)

# Add note to incident
session.rpost(
    f"/incidents/{incident['id']}/notes",
    json={
        'note': {
            'content': 'Investigating high CPU usage. Scaling up instances.'
        }
    }
)

# Resolve incident
session.rput(
    f"/incidents/{incident['id']}",
    json={
        'incident': {
            'type': 'incident_reference',
            'status': 'resolved',
            'resolution': 'Scaled up instances and optimized queries.'
        }
    }
)
```

### On-Call Management

```python
from pdpyras import APISession
from datetime import datetime, timedelta
import os

session = APISession(os.environ['PD_API_TOKEN'])

# Get current on-call users for all schedules
oncalls = session.list_all('oncalls')

for oncall in oncalls:
    user = oncall.get('user', {})
    schedule = oncall.get('schedule', {})
    escalation = oncall.get('escalation_policy', {})

    print(f"User: {user.get('summary', 'Unknown')}")
    print(f"  Schedule: {schedule.get('summary', 'Direct assignment')}")
    print(f"  Policy: {escalation.get('summary', 'Unknown')}")
    print(f"  Level: {oncall.get('escalation_level', 1)}")
    print()

# Create schedule override
override_start = datetime.utcnow()
override_end = override_start + timedelta(hours=8)

session.rpost(
    '/schedules/PXXXXXX/overrides',
    json={
        'overrides': [{
            'start': override_start.isoformat() + 'Z',
            'end': override_end.isoformat() + 'Z',
            'user': {
                'id': 'PUSER01',
                'type': 'user_reference'
            }
        }]
    }
)
```

### Service Management

```python
from pdpyras import APISession
import os

session = APISession(os.environ['PD_API_TOKEN'])

# List all services
services = session.list_all('services')
for svc in services:
    print(f"{svc['name']} ({svc['status']}) - {svc['id']}")

# Create new service
new_service = session.rpost(
    '/services',
    json={
        'service': {
            'name': 'new-microservice',
            'description': 'New microservice for order processing',
            'escalation_policy': {
                'id': 'PXXXXXX',
                'type': 'escalation_policy_reference'
            },
            'alert_creation': 'create_alerts_and_incidents',
            'incident_urgency_rule': {
                'type': 'constant',
                'urgency': 'high'
            },
            'auto_resolve_timeout': 14400,
            'acknowledgement_timeout': 1800
        }
    }
)

# Add integration to service
integration = session.rpost(
    f"/services/{new_service['id']}/integrations",
    json={
        'integration': {
            'type': 'events_api_v2_inbound_integration',
            'name': 'Events API'
        }
    }
)

print(f"Integration Key: {integration['integration_key']}")
```

## Node.js Examples

### Send Alerts

```javascript
import { event } from '@pagerduty/pdjs';

const pdEvents = event({ routingKey: process.env.PD_ROUTING_KEY });

// Trigger alert
async function triggerAlert() {
  const response = await pdEvents.sendEvent({
    event_action: 'trigger',
    dedup_key: 'srv01-disk-space',
    payload: {
      summary: 'Disk space critical on srv01',
      severity: 'critical',
      source: 'disk-monitor',
      component: 'storage',
      group: 'infrastructure',
      class: 'disk',
      custom_details: {
        disk_usage: '95%',
        mount_point: '/data',
        available_gb: 5,
      },
    },
    links: [
      {
        href: 'https://monitoring.example.com/srv01',
        text: 'View in Monitoring',
      },
    ],
    images: [
      {
        src: 'https://monitoring.example.com/graphs/disk.png',
        alt: 'Disk usage graph',
      },
    ],
  });

  console.log('Alert triggered:', response.data);
  return response.data.dedup_key;
}

// Acknowledge alert
async function acknowledgeAlert(dedupKey) {
  await pdEvents.sendEvent({
    event_action: 'acknowledge',
    dedup_key: dedupKey,
  });
  console.log('Alert acknowledged');
}

// Resolve alert
async function resolveAlert(dedupKey) {
  await pdEvents.sendEvent({
    event_action: 'resolve',
    dedup_key: dedupKey,
  });
  console.log('Alert resolved');
}

// Usage
const dedupKey = await triggerAlert();
// ... investigation ...
await acknowledgeAlert(dedupKey);
// ... fix applied ...
await resolveAlert(dedupKey);
```

### Manage Incidents

```javascript
import { api } from '@pagerduty/pdjs';

const pd = api({ token: process.env.PD_API_TOKEN });

// List incidents
async function listIncidents(status = ['triggered', 'acknowledged']) {
  const response = await pd.get('/incidents', {
    data: {
      'statuses[]': status,
      sort_by: 'created_at:desc',
      limit: 25,
    },
  });

  return response.data.incidents;
}

// Create incident
async function createIncident(title, serviceId, urgency = 'high') {
  const response = await pd.post('/incidents', {
    data: {
      incident: {
        type: 'incident',
        title,
        service: {
          id: serviceId,
          type: 'service_reference',
        },
        urgency,
        body: {
          type: 'incident_body',
          details: 'Created via API',
        },
      },
    },
  });

  return response.data.incident;
}

// Update incident status
async function updateIncidentStatus(incidentId, status) {
  const response = await pd.put(`/incidents/${incidentId}`, {
    data: {
      incident: {
        type: 'incident_reference',
        status,
      },
    },
  });

  return response.data.incident;
}

// Add note to incident
async function addIncidentNote(incidentId, content) {
  const response = await pd.post(`/incidents/${incidentId}/notes`, {
    data: {
      note: { content },
    },
  });

  return response.data.note;
}

// Usage
const incidents = await listIncidents();
console.log(`Found ${incidents.length} open incidents`);

for (const incident of incidents) {
  console.log(`[${incident.status}] ${incident.title}`);
}
```

### Webhook Handler (Express.js)

```javascript
import express from 'express';
import crypto from 'crypto';

const app = express();

const WEBHOOK_SECRET = process.env.PD_WEBHOOK_SECRET;

// Verify webhook signature
function verifySignature(payload, signature) {
  const expected = crypto
    .createHmac('sha256', WEBHOOK_SECRET)
    .update(payload)
    .digest('hex');

  const provided = signature.replace('v1=', '');
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(provided));
}

// Raw body parser for signature verification
app.use('/webhooks/pagerduty', express.raw({ type: 'application/json' }));

app.post('/webhooks/pagerduty', (req, res) => {
  const signature = req.headers['x-pagerduty-signature'];

  if (!verifySignature(req.body, signature)) {
    return res.status(401).send('Invalid signature');
  }

  const event = JSON.parse(req.body);
  const { event_type, data } = event.event;

  console.log(`Received event: ${event_type}`);

  switch (event_type) {
    case 'incident.triggered':
      handleIncidentTriggered(data);
      break;
    case 'incident.acknowledged':
      handleIncidentAcknowledged(data);
      break;
    case 'incident.resolved':
      handleIncidentResolved(data);
      break;
    default:
      console.log(`Unhandled event type: ${event_type}`);
  }

  res.status(200).send('OK');
});

function handleIncidentTriggered(incident) {
  console.log(`Incident triggered: ${incident.title}`);
  // Send to Slack, update dashboard, create ticket, etc.
}

function handleIncidentAcknowledged(incident) {
  console.log(`Incident acknowledged: ${incident.title}`);
}

function handleIncidentResolved(incident) {
  console.log(`Incident resolved: ${incident.title}`);
}

app.listen(3000, () => {
  console.log('Webhook server listening on port 3000');
});
```

## AlertManager Integration

### AlertManager Configuration

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m

route:
  receiver: 'pagerduty-critical'
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

  routes:
    # Critical alerts -> PagerDuty high urgency
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      continue: true

    # Warning alerts -> PagerDuty low urgency
    - match:
        severity: warning
      receiver: 'pagerduty-warning'

    # Info alerts -> Don't page
    - match:
        severity: info
      receiver: 'null'

receivers:
  - name: 'null'

  - name: 'pagerduty-critical'
    pagerduty_configs:
      - routing_key: 'YOUR_CRITICAL_ROUTING_KEY'
        severity: critical
        description: '{{ .CommonAnnotations.summary }}'
        details:
          firing: '{{ template "pagerduty.default.instances" .Alerts.Firing }}'
          resolved: '{{ template "pagerduty.default.instances" .Alerts.Resolved }}'
          num_firing: '{{ .Alerts.Firing | len }}'
          num_resolved: '{{ .Alerts.Resolved | len }}'
        links:
          - href: '{{ (index .Alerts 0).GeneratorURL }}'
            text: 'View in Prometheus'
          - href: 'https://grafana.example.com/d/alerts'
            text: 'View in Grafana'

  - name: 'pagerduty-warning'
    pagerduty_configs:
      - routing_key: 'YOUR_WARNING_ROUTING_KEY'
        severity: warning
        description: '{{ .CommonAnnotations.summary }}'
```

### Prometheus Alert Rules

```yaml
# prometheus-rules.yml
groups:
  - name: infrastructure
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
        for: 5m
        labels:
          severity: critical
          team: infrastructure
        annotations:
          summary: 'High CPU usage on {{ $labels.instance }}'
          description: 'CPU usage is {{ $value | printf "%.1f" }}%'
          runbook_url: 'https://wiki.example.com/runbooks/high-cpu'

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 10
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: 'Disk space low on {{ $labels.instance }}'
          description: 'Only {{ $value | printf "%.1f" }}% disk space remaining'

      - alert: ServiceDown
        expr: up == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: 'Service {{ $labels.job }} is down'
          description: '{{ $labels.instance }} has been down for more than 2 minutes'
```

## Kubernetes Integration

### Kubernetes Operator Events

```yaml
# pagerduty-kubernetes-integration.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pagerduty-config
  namespace: monitoring
data:
  PAGERDUTY_ROUTING_KEY: 'YOUR_ROUTING_KEY'
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubernetes-pagerduty-bridge
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: k8s-pd-bridge
  template:
    metadata:
      labels:
        app: k8s-pd-bridge
    spec:
      serviceAccountName: pagerduty-bridge
      containers:
        - name: bridge
          image: your-registry/k8s-pagerduty-bridge:1.0.0
          env:
            - name: PAGERDUTY_ROUTING_KEY
              valueFrom:
                secretKeyRef:
                  name: pagerduty-secrets
                  key: routing-key
          resources:
            limits:
              memory: '128Mi'
              cpu: '100m'
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pagerduty-bridge
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pagerduty-bridge
rules:
  - apiGroups: ['']
    resources: ['events', 'pods', 'nodes']
    verbs: ['get', 'list', 'watch']
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: pagerduty-bridge
subjects:
  - kind: ServiceAccount
    name: pagerduty-bridge
    namespace: monitoring
roleRef:
  kind: ClusterRole
  name: pagerduty-bridge
  apiGroup: rbac.authorization.k8s.io
```

### Helm Values for AlertManager

```yaml
# values-alertmanager.yaml
alertmanager:
  config:
    global:
      resolve_timeout: 5m
      pagerduty_url: https://events.pagerduty.com/v2/enqueue

    route:
      receiver: 'pagerduty'
      group_by: ['alertname', 'namespace', 'pod']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 4h
      routes:
        - match:
            severity: critical
          receiver: 'pagerduty'

    receivers:
      - name: 'pagerduty'
        pagerduty_configs:
          - routing_key_file: /etc/alertmanager/secrets/pagerduty-routing-key
            send_resolved: true

  extraSecretMounts:
    - name: pagerduty-secrets
      mountPath: /etc/alertmanager/secrets
      secretName: alertmanager-pagerduty
      readOnly: true
```

## Change Events

### Send Change Events

```python
import requests
import os
from datetime import datetime

def send_change_event(routing_key: str, summary: str, source: str,
                       custom_details: dict = None, links: list = None):
    """Send a change event to PagerDuty for deployment correlation."""

    payload = {
        "routing_key": routing_key,
        "payload": {
            "summary": summary,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "source": source,
            "custom_details": custom_details or {}
        },
        "links": links or []
    }

    response = requests.post(
        "https://events.pagerduty.com/v2/change/enqueue",
        json=payload,
        headers={"Content-Type": "application/json"}
    )

    response.raise_for_status()
    return response.json()

# Usage in CI/CD pipeline
routing_key = os.environ['PD_CHANGE_ROUTING_KEY']

send_change_event(
    routing_key=routing_key,
    summary="Deployed api-service v2.5.0 to production",
    source="github-actions",
    custom_details={
        "service": "api-service",
        "version": "v2.5.0",
        "environment": "production",
        "deployer": os.environ.get('GITHUB_ACTOR', 'unknown'),
        "commit": os.environ.get('GITHUB_SHA', 'unknown'),
        "pull_request": os.environ.get('GITHUB_PR_NUMBER', 'N/A')
    },
    links=[
        {
            "href": f"https://github.com/org/repo/commit/{os.environ.get('GITHUB_SHA', '')}",
            "text": "View Commit"
        },
        {
            "href": f"https://github.com/org/repo/actions/runs/{os.environ.get('GITHUB_RUN_ID', '')}",
            "text": "View Pipeline"
        }
    ]
)
```

### GitHub Actions Integration

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy Application
        run: |
          # Your deployment steps here
          kubectl apply -f k8s/

      - name: Send Change Event to PagerDuty
        if: success()
        env:
          PD_ROUTING_KEY: ${{ secrets.PAGERDUTY_CHANGE_ROUTING_KEY }}
        run: |
          curl -X POST \
            "https://events.pagerduty.com/v2/change/enqueue" \
            -H "Content-Type: application/json" \
            -d '{
              "routing_key": "'"$PD_ROUTING_KEY"'",
              "payload": {
                "summary": "Deployed ${{ github.repository }} to production",
                "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
                "source": "github-actions",
                "custom_details": {
                  "repository": "${{ github.repository }}",
                  "commit": "${{ github.sha }}",
                  "actor": "${{ github.actor }}",
                  "ref": "${{ github.ref }}",
                  "run_id": "${{ github.run_id }}"
                }
              },
              "links": [
                {
                  "href": "https://github.com/${{ github.repository }}/commit/${{ github.sha }}",
                  "text": "View Commit"
                }
              ]
            }'
```

## Troubleshooting

| Issue                   | Cause                     | Solution                                             |
| ----------------------- | ------------------------- | ---------------------------------------------------- |
| Alerts not triggering   | Invalid routing key       | Verify integration key in service settings           |
| Duplicate incidents     | Missing dedup_key         | Include unique dedup_key in all events               |
| Webhook failures        | Signature mismatch        | Ensure using raw body for signature verification     |
| No notifications        | User contact not verified | Check user notification rules and verify phone/email |
| High noise              | Missing event rules       | Configure alert grouping and suppression rules       |
| Escalations not working | Schedule timezone issues  | Verify schedule timezone matches user timezone       |
| API rate limits         | Too many requests         | Implement exponential backoff, use pagination        |
| Missing alerts          | Suppression rules active  | Check global and service event rules                 |

### Debug API Calls

```bash
# Enable verbose output
curl -v -X GET \
  "https://api.pagerduty.com/incidents" \
  -H "Authorization: Token token=$PD_API_TOKEN" \
  -H "Content-Type: application/json" 2>&1 | head -50

# Check rate limits
curl -s -I -X GET \
  "https://api.pagerduty.com/users" \
  -H "Authorization: Token token=$PD_API_TOKEN" | grep -i x-ratelimit

# X-RateLimit-Limit: 900
# X-RateLimit-Remaining: 895
# X-RateLimit-Reset: 1705312800
```

### Validate Events

```bash
# Test event trigger
curl -s -X POST \
  "https://events.pagerduty.com/v2/enqueue" \
  -H "Content-Type: application/json" \
  -d '{
    "routing_key": "YOUR_ROUTING_KEY",
    "event_action": "trigger",
    "dedup_key": "test-'$(date +%s)'",
    "payload": {
      "summary": "Test alert - please ignore",
      "severity": "info",
      "source": "test-script"
    }
  }' | jq .

# Expected response:
# {
#   "status": "success",
#   "message": "Event processed",
#   "dedup_key": "test-1705312800"
# }
```

## Best Practices

### Incident Management

1. **Use meaningful dedup_keys** - Include service, host, and check name
2. **Set appropriate severity** - critical, error, warning, info
3. **Include runbook links** - Help responders resolve faster
4. **Add custom_details** - Provide context for investigation
5. **Send resolve events** - Auto-resolve when issue clears

### On-Call Health

1. **Limit on-call shifts** - Max 7 days, prefer shorter rotations
2. **Ensure coverage overlap** - Handoff meetings between shifts
3. **Monitor interrupt metrics** - Track after-hours pages
4. **Regular schedule audits** - Review and update quarterly
5. **Backup responders** - Always have secondary escalation

### Alert Quality

1. **Reduce noise** - Use event rules to suppress flaky alerts
2. **Enable intelligent grouping** - Reduce incident count
3. **Set support hours** - Lower urgency outside business hours
4. **Review regularly** - Monthly alert hygiene reviews
5. **Track MTTA/MTTR** - Set targets and measure improvement

### Security

1. **Use scoped tokens** - Minimum required permissions
2. **Rotate API tokens** - Every 90 days
3. **Verify webhooks** - Always validate signatures
4. **Audit access** - Review user permissions quarterly
5. **Enable SSO** - Use SAML/OIDC for authentication
