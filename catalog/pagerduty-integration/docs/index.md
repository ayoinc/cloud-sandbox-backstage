# PagerDuty Incident Management

Enterprise incident response and on-call management platform for reliable service operations.

## Quick Start

### Prerequisites

- PagerDuty account (Business or Digital Operations plan recommended)
- API access token with appropriate permissions
- Service integration keys for your applications

### Get Your API Token

```bash
# Navigate to PagerDuty Web UI
# User Icon -> My Profile -> User Settings -> Create API User Token

# Or use the REST API to verify your token
curl -s -X GET \
  --url "https://api.pagerduty.com/users/me" \
  -H "Authorization: Token token=YOUR_API_TOKEN" \
  -H "Content-Type: application/json" | jq .
```

### Create Your First Service

```bash
# List existing escalation policies
curl -s -X GET \
  --url "https://api.pagerduty.com/escalation_policies" \
  -H "Authorization: Token token=$PD_API_TOKEN" \
  -H "Content-Type: application/json" | jq '.escalation_policies[] | {id, name}'

# Create a new service
curl -s -X POST \
  --url "https://api.pagerduty.com/services" \
  -H "Authorization: Token token=$PD_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "service": {
      "name": "production-api",
      "description": "Production API Service",
      "escalation_policy": {
        "id": "PXXXXXX",
        "type": "escalation_policy_reference"
      },
      "alert_creation": "create_alerts_and_incidents",
      "incident_urgency_rule": {
        "type": "constant",
        "urgency": "high"
      }
    }
  }' | jq .
```

### Trigger Your First Alert

```bash
# Using Events API v2
curl -s -X POST \
  --url "https://events.pagerduty.com/v2/enqueue" \
  -H "Content-Type: application/json" \
  -d '{
    "routing_key": "YOUR_INTEGRATION_KEY",
    "event_action": "trigger",
    "dedup_key": "test-alert-001",
    "payload": {
      "summary": "Test alert from integration",
      "severity": "warning",
      "source": "test-system",
      "component": "api-server",
      "group": "production",
      "class": "performance",
      "custom_details": {
        "cpu_usage": 95,
        "memory_usage": 88
      }
    }
  }' | jq .
```

## Features

| Feature                  | Description                            | Plan Required |
| ------------------------ | -------------------------------------- | ------------- |
| **Incident Management**  | Create, acknowledge, resolve incidents | All           |
| **On-Call Scheduling**   | Rotation schedules with overrides      | All           |
| **Escalation Policies**  | Multi-level escalation chains          | All           |
| **Event Intelligence**   | AIOps noise reduction, alert grouping  | Business+     |
| **Service Dependencies** | Map service relationships              | Business+     |
| **Analytics**            | MTTA, MTTR, incident metrics           | Business+     |
| **Automation Actions**   | Runbook automation, diagnostics        | Digital Ops   |
| **Status Dashboard**     | Public status page integration         | Business+     |
| **Change Events**        | Correlate deployments with incidents   | All           |
| **Webhooks**             | Real-time event notifications          | All           |

## Architecture Overview

```d2
direction: down

monitoring: Monitoring Systems {
  style.fill: "#e8f5e9"
  prometheus: Prometheus
  datadog: Datadog
  newrelic: New Relic
  custom: Custom Apps
}

pagerduty: PagerDuty Platform {
  style.fill: "#e3f2fd"

  events: Events API v2 {
    style.fill: "#fff3e0"
  }

  intelligence: Event Intelligence {
    style.fill: "#fce4ec"
    dedup: Deduplication
    grouping: Grouping
    suppression: Suppression
  }

  service: Service {
    style.fill: "#f3e5f5"
  }

  integration: Integration Key {
    style.fill: "#e0f7fa"
  }

  lifecycle: Incident Lifecycle {
    style.fill: "#fff8e1"
    triggered: Triggered
    ack: Acknowledged
    resolved: Resolved
  }

  postmortem: Postmortem / Review {
    style.fill: "#efebe9"
    analytics: Analytics
    reports: Reports
  }
}

responders: Responders {
  style.fill: "#f3e5f5"
  mobile: Mobile App (iOS/Android)
  email: Email / SMS
  phone: Phone Calls
  slack: Slack / Teams
  escalation: Escalation Policy
}

monitoring -> pagerduty.events: alerts
pagerduty.events -> pagerduty.intelligence
pagerduty.intelligence -> pagerduty.service
pagerduty.integration -> pagerduty.service
pagerduty.service -> pagerduty.lifecycle
pagerduty.lifecycle -> pagerduty.postmortem
pagerduty.service -> responders.escalation: notify
responders.escalation -> responders.mobile
responders.escalation -> responders.email
responders.escalation -> responders.phone
responders.escalation -> responders.slack
```

## Integration Methods

| Method                  | Use Case                          | Endpoint                                    |
| ----------------------- | --------------------------------- | ------------------------------------------- |
| **Events API v2**       | Send alerts from monitoring       | `events.pagerduty.com/v2/enqueue`           |
| **REST API v2**         | Manage services, users, incidents | `api.pagerduty.com/*`                       |
| **Webhooks v3**         | Receive incident updates          | Your endpoint                               |
| **Email Integration**   | Legacy email-based alerts         | `your-service@your-subdomain.pagerduty.com` |
| **Native Integrations** | Pre-built 700+ integrations       | Various                                     |

## CLI Installation

```bash
# Install PagerDuty CLI (pd)
brew install pagerduty-cli

# Or via npm
npm install -g pagerduty-cli

# Configure authentication
pd auth login

# Verify connection
pd user me

# List services
pd service list

# List on-call users
pd oncall list

# Trigger test incident
pd incident create --title "Test incident" --service-id PXXXXXX
```

## Related Documentation

- [Overview](overview.md) - Deep dive into architecture, configuration, and security
- [Usage](usage.md) - Integration examples, SDK usage, and troubleshooting
