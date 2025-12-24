# PagerDuty Overview

## Platform Architecture

### Core Components

```d2
direction: down

platform: PagerDuty Platform {
  style.fill: "#e3f2fd"

  ingestion: Event Ingestion {
    style.fill: "#e8f5e9"
    ingest: Event Ingest {
      api: Events API
      email: Email
      integrations: Integrations
    }
    processing: Event Processing {
      dedup: Deduplication
      grouping: Grouping
      suppression: Suppression
    }
    routing: Routing {
      services: Services
      teams: Teams
      schedules: Schedules
    }
  }

  management: Incident Management {
    style.fill: "#fff3e0"
    alerts: Alert Management {
      severity: Severity
      priority: Priority
      fields: Custom Fields
    }
    lifecycle: Incident Lifecycle {
      triggered: Triggered
      ack: Acknowledged
      resolved: Resolved
    }
    notifications: Notifications {
      push: Push
      sms: SMS
      phone: Phone
    }
  }

  ingestion.ingest -> ingestion.processing
  ingestion.processing -> ingestion.routing
  ingestion.routing -> management.alerts
  management.alerts -> management.lifecycle
  management.lifecycle -> management.notifications
}
```

### Service Hierarchy

```
Organization
├── Teams
│   ├── Team A (Platform)
│   │   ├── Services
│   │   │   ├── api-gateway
│   │   │   ├── auth-service
│   │   │   └── user-service
│   │   ├── Escalation Policies
│   │   │   └── platform-oncall
│   │   └── Schedules
│   │       └── platform-rotation
│   │
│   └── Team B (Infrastructure)
│       ├── Services
│       │   ├── kubernetes-cluster
│       │   ├── database-primary
│       │   └── cdn-edge
│       ├── Escalation Policies
│       │   └── infra-oncall
│       └── Schedules
│           └── infra-rotation
│
└── Business Services (Dependencies)
    ├── Customer Portal
    │   └── depends_on: [api-gateway, auth-service]
    └── Payment Processing
        └── depends_on: [payment-service, database-primary]
```

## Event Intelligence

### Alert Grouping

```yaml
# Intelligent alert grouping configuration
alert_grouping_parameters:
  type: intelligent
  config:
    # Time-based grouping window
    time_window: 300 # 5 minutes

    # Fields used for grouping
    fields:
      - source
      - component
      - class

    # Recommended: Use intelligent grouping
    # Options: time, intelligent, content_based
```

### Noise Reduction

```
Raw Alerts (1000/hour)
        │
        v
+-------------------+
| Event Intelligence|
| - Deduplication   | ──> Duplicates suppressed (600)
| - Grouping        | ──> Grouped into 50 incidents
| - Suppression     | ──> Maintenance windows (100)
+-------------------+
        │
        v
Actionable Incidents (50/hour)
        │
        v
+-------------------+
| Priority Routing  |
| - P1: Immediate   | ──> 5 incidents
| - P2: 15 minutes  | ──> 15 incidents
| - P3: 1 hour      | ──> 30 incidents
+-------------------+
```

## Configuration

### Service Configuration

```json
{
  "service": {
    "name": "production-api",
    "description": "Production API Service",
    "status": "active",
    "escalation_policy": {
      "id": "PXXXXXX",
      "type": "escalation_policy_reference"
    },
    "alert_creation": "create_alerts_and_incidents",
    "alert_grouping_parameters": {
      "type": "intelligent"
    },
    "incident_urgency_rule": {
      "type": "use_support_hours",
      "during_support_hours": {
        "type": "constant",
        "urgency": "high"
      },
      "outside_support_hours": {
        "type": "constant",
        "urgency": "low"
      }
    },
    "support_hours": {
      "type": "fixed_time_per_day",
      "time_zone": "America/New_York",
      "days_of_week": [1, 2, 3, 4, 5],
      "start_time": "09:00:00",
      "end_time": "17:00:00"
    },
    "auto_resolve_timeout": 14400,
    "acknowledgement_timeout": 1800
  }
}
```

### Escalation Policy

```json
{
  "escalation_policy": {
    "name": "Production On-Call",
    "description": "24/7 production support escalation",
    "num_loops": 2,
    "on_call_handoff_notifications": "if_has_services",
    "escalation_rules": [
      {
        "escalation_delay_in_minutes": 5,
        "targets": [
          {
            "id": "PXXXXXX",
            "type": "schedule_reference"
          }
        ]
      },
      {
        "escalation_delay_in_minutes": 15,
        "targets": [
          {
            "id": "PXXXXXX",
            "type": "user_reference"
          },
          {
            "id": "PYYYYYY",
            "type": "user_reference"
          }
        ]
      },
      {
        "escalation_delay_in_minutes": 30,
        "targets": [
          {
            "id": "PZZZZZZ",
            "type": "user_reference"
          }
        ]
      }
    ]
  }
}
```

### On-Call Schedule

```json
{
  "schedule": {
    "name": "Primary On-Call",
    "description": "Weekly rotation for primary responders",
    "time_zone": "America/New_York",
    "schedule_layers": [
      {
        "name": "Layer 1 - Primary",
        "start": "2024-01-01T00:00:00-05:00",
        "rotation_virtual_start": "2024-01-01T09:00:00-05:00",
        "rotation_turn_length_seconds": 604800,
        "users": [
          { "user": { "id": "PUSER01", "type": "user_reference" } },
          { "user": { "id": "PUSER02", "type": "user_reference" } },
          { "user": { "id": "PUSER03", "type": "user_reference" } },
          { "user": { "id": "PUSER04", "type": "user_reference" } }
        ],
        "restrictions": [
          {
            "type": "daily_restriction",
            "start_time_of_day": "09:00:00",
            "duration_seconds": 32400,
            "start_day_of_week": 1
          }
        ]
      }
    ],
    "overrides": []
  }
}
```

## Event Rules

### Global Event Rules

```json
{
  "rule": {
    "label": "Suppress known flaky alerts",
    "disabled": false,
    "conditions": {
      "operator": "and",
      "subconditions": [
        {
          "operator": "contains",
          "parameters": {
            "path": "payload.summary",
            "value": "flaky-test"
          }
        },
        {
          "operator": "equals",
          "parameters": {
            "path": "payload.severity",
            "value": "warning"
          }
        }
      ]
    },
    "actions": {
      "suppress": {
        "value": true,
        "threshold_value": 10,
        "threshold_time_unit": "minutes"
      }
    }
  }
}
```

### Service Event Rules

```json
{
  "rule": {
    "label": "Set high priority for database alerts",
    "conditions": {
      "operator": "and",
      "subconditions": [
        {
          "operator": "contains",
          "parameters": {
            "path": "payload.source",
            "value": "database"
          }
        }
      ]
    },
    "actions": {
      "priority": {
        "value": "P1"
      },
      "annotate": {
        "value": "Database alert - check replication status"
      },
      "extractions": [
        {
          "target": "dedup_key",
          "source": "payload.custom_details.db_instance",
          "regex": "(.+)"
        }
      ]
    }
  }
}
```

## Webhooks v3

### Webhook Configuration

```json
{
  "webhook_subscription": {
    "type": "webhook_subscription",
    "delivery_method": {
      "type": "http_delivery_method",
      "url": "https://your-app.com/webhooks/pagerduty",
      "custom_headers": [
        {
          "name": "X-Custom-Header",
          "value": "your-value"
        }
      ],
      "secret": "your-webhook-secret"
    },
    "description": "Incident updates webhook",
    "events": [
      "incident.triggered",
      "incident.acknowledged",
      "incident.resolved",
      "incident.escalated",
      "incident.reassigned",
      "incident.priority_updated"
    ],
    "filter": {
      "type": "service_reference",
      "id": "PXXXXXX"
    },
    "active": true
  }
}
```

### Webhook Payload Structure

```json
{
  "event": {
    "id": "01DXXXXXX",
    "event_type": "incident.triggered",
    "resource_type": "incident",
    "occurred_at": "2024-01-15T10:30:00.000Z",
    "agent": {
      "type": "service_reference",
      "id": "PXXXXXX"
    },
    "client": null,
    "data": {
      "id": "Q1XXXXXX",
      "type": "incident",
      "self": "https://api.pagerduty.com/incidents/Q1XXXXXX",
      "html_url": "https://your-subdomain.pagerduty.com/incidents/Q1XXXXXX",
      "number": 12345,
      "status": "triggered",
      "incident_key": "srv01/disk_space",
      "created_at": "2024-01-15T10:30:00Z",
      "title": "Disk space critical on srv01",
      "service": {
        "id": "PXXXXXX",
        "type": "service_reference",
        "summary": "Production API"
      },
      "assignees": [
        {
          "id": "PUSER01",
          "type": "user_reference",
          "summary": "John Doe"
        }
      ],
      "escalation_policy": {
        "id": "PXXXXXX",
        "type": "escalation_policy_reference",
        "summary": "Production On-Call"
      },
      "urgency": "high",
      "priority": {
        "id": "PXXXXXX",
        "type": "priority_reference",
        "summary": "P1"
      }
    }
  }
}
```

## Security

### API Token Types

| Token Type        | Scope               | Use Case              |
| ----------------- | ------------------- | --------------------- |
| **User Token**    | User's permissions  | CLI, personal scripts |
| **Account Token** | Full account access | Admin automation      |
| **Scoped OAuth**  | Limited permissions | Third-party apps      |

### Token Best Practices

```bash
# Store tokens securely
export PD_API_TOKEN=$(vault kv get -field=token secret/pagerduty/api)

# Use scoped tokens for automation
# Request only needed scopes:
# - incidents:read
# - incidents:write
# - services:read
# - users:read

# Rotate tokens regularly
# Set up token expiration alerts
```

### Webhook Security

```python
import hmac
import hashlib
import json

def verify_webhook_signature(payload: bytes, signature: str, secret: str) -> bool:
    """Verify PagerDuty webhook signature (v3)."""
    # Compute expected signature
    expected = hmac.new(
        secret.encode('utf-8'),
        payload,
        hashlib.sha256
    ).hexdigest()

    # Extract signature from header
    # Format: v1=<signature>
    provided = signature.split('=')[1] if '=' in signature else signature

    return hmac.compare_digest(expected, provided)


# Flask example
from flask import Flask, request, abort

app = Flask(__name__)
WEBHOOK_SECRET = os.environ['PD_WEBHOOK_SECRET']

@app.route('/webhooks/pagerduty', methods=['POST'])
def handle_webhook():
    signature = request.headers.get('X-PagerDuty-Signature')

    if not verify_webhook_signature(request.data, signature, WEBHOOK_SECRET):
        abort(401)

    event = request.json
    # Process event...
    return '', 200
```

### Network Security

```yaml
# Firewall rules for PagerDuty webhooks
# Allow inbound from PagerDuty IP ranges
ingress:
  - from_ip: 52.21.40.0/24 # US East
  - from_ip: 52.31.64.0/24 # EU West
  - from_ip: 13.236.32.0/24 # AP Southeast

# TLS requirements
tls:
  min_version: '1.2'
  ciphers:
    - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
    - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
```

## Monitoring PagerDuty

### Key Metrics

| Metric              | Description                      | Target        |
| ------------------- | -------------------------------- | ------------- |
| **MTTA**            | Mean Time to Acknowledge         | < 5 minutes   |
| **MTTR**            | Mean Time to Resolve             | < 1 hour      |
| **Escalation Rate** | % incidents escalated            | < 10%         |
| **After-Hours %**   | Incidents outside business hours | Monitor trend |
| **High-Urgency %**  | % of high-urgency incidents      | < 20%         |

### Analytics API

```bash
# Get incident analytics
curl -s -X GET \
  "https://api.pagerduty.com/analytics/metrics/incidents/all" \
  -H "Authorization: Token token=$PD_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-EARLY-ACCESS: analytics-v2" \
  -d '{
    "filters": {
      "created_at_start": "2024-01-01T00:00:00Z",
      "created_at_end": "2024-01-31T23:59:59Z",
      "service_ids": ["PXXXXXX"]
    },
    "aggregate_unit": "day"
  }' | jq .

# Response includes:
# - mean_seconds_to_resolve
# - mean_seconds_to_first_ack
# - total_incident_count
# - total_interruptions
```

### Prometheus Exporter

```yaml
# prometheus-pagerduty-exporter configuration
pagerduty:
  token: ${PD_API_TOKEN}

metrics:
  - name: pagerduty_incidents_total
    type: counter
    help: Total number of incidents
    labels: [service, urgency, status]

  - name: pagerduty_mtta_seconds
    type: gauge
    help: Mean time to acknowledge
    labels: [service]

  - name: pagerduty_mttr_seconds
    type: gauge
    help: Mean time to resolve
    labels: [service]

  - name: pagerduty_oncall_user
    type: gauge
    help: Currently on-call user
    labels: [schedule, user]
```

## High Availability

### Redundancy Patterns

```
Primary Monitoring Path:
Prometheus -> AlertManager -> PagerDuty Events API

Secondary Monitoring Path:
Prometheus -> Grafana OnCall -> PagerDuty Events API (backup)

Dead Man's Switch:
Heartbeat Monitor -> PagerDuty -> Alert if no heartbeat
```

### Heartbeat Monitoring

```bash
# Create heartbeat integration
# In PagerDuty: Services -> Add Integration -> Heartbeat

# Send heartbeat every 5 minutes
*/5 * * * * curl -s -X GET \
  "https://events.pagerduty.com/integration/HEARTBEAT_KEY/check" \
  || echo "Heartbeat failed" | logger -t pagerduty

# Alternative: Events API v2
curl -X POST \
  "https://events.pagerduty.com/v2/enqueue" \
  -H "Content-Type: application/json" \
  -d '{
    "routing_key": "INTEGRATION_KEY",
    "event_action": "trigger",
    "dedup_key": "heartbeat",
    "payload": {
      "summary": "Monitoring heartbeat",
      "severity": "info",
      "source": "monitoring-system"
    }
  }'
```

## Terraform Provider

```hcl
terraform {
  required_providers {
    pagerduty = {
      source  = "PagerDuty/pagerduty"
      version = "~> 3.0"
    }
  }
}

provider "pagerduty" {
  token = var.pagerduty_token
}

# Create team
resource "pagerduty_team" "platform" {
  name        = "Platform Team"
  description = "Platform engineering team"
}

# Create escalation policy
resource "pagerduty_escalation_policy" "platform_oncall" {
  name      = "Platform On-Call"
  num_loops = 2
  teams     = [pagerduty_team.platform.id]

  rule {
    escalation_delay_in_minutes = 5
    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.platform_primary.id
    }
  }

  rule {
    escalation_delay_in_minutes = 15
    target {
      type = "user_reference"
      id   = pagerduty_user.manager.id
    }
  }
}

# Create service
resource "pagerduty_service" "api" {
  name                    = "production-api"
  description            = "Production API Service"
  escalation_policy      = pagerduty_escalation_policy.platform_oncall.id
  alert_creation         = "create_alerts_and_incidents"
  auto_resolve_timeout   = 14400
  acknowledgement_timeout = 1800

  alert_grouping_parameters {
    type = "intelligent"
  }

  incident_urgency_rule {
    type    = "constant"
    urgency = "high"
  }
}

# Create service integration
resource "pagerduty_service_integration" "prometheus" {
  name    = "Prometheus"
  service = pagerduty_service.api.id
  vendor  = data.pagerduty_vendor.prometheus.id
}

data "pagerduty_vendor" "prometheus" {
  name = "Prometheus"
}

# Output integration key
output "prometheus_integration_key" {
  value     = pagerduty_service_integration.prometheus.integration_key
  sensitive = true
}
```
