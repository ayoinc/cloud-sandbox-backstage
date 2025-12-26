# New Relic Integration Overview

## Architecture Deep Dive

### Agent Types

```d2
direction: right

title: New Relic Agent Ecosystem {
  shape: text
  near: top-center
  style.font-size: 24
}

agents: New Relic Agents {
  style.fill: "#E3F2FD"

  row1: Infrastructure & APM {
    style.fill: "#BBDEFB"

    infra: Infrastructure Agent {
      shape: hexagon
      style.fill: "#2196F3"
      style.font-color: white
    }
    infra_desc: |md
      - Host metrics
      - Processes
      - Containers
      - Integrations
    | {
      shape: document
      style.fill: "#E3F2FD"
    }

    apm: APM Agent {
      shape: hexagon
      style.fill: "#2196F3"
      style.font-color: white
    }
    apm_desc: |md
      - Transactions
      - Errors
      - DB queries
      - External calls
    | {
      shape: document
      style.fill: "#E3F2FD"
    }

    browser: Browser Agent {
      shape: hexagon
      style.fill: "#2196F3"
      style.font-color: white
    }
    browser_desc: |md
      - Page loads
      - Ajax calls
      - JS errors
      - User sessions
    | {
      shape: document
      style.fill: "#E3F2FD"
    }

    infra -> infra_desc
    apm -> apm_desc
    browser -> browser_desc
  }

  row2: Mobile & Synthetics {
    style.fill: "#E8F5E9"

    mobile: Mobile Agent {
      shape: hexagon
      style.fill: "#4CAF50"
      style.font-color: white
    }
    mobile_desc: |md
      - Crashes
      - HTTP errors
      - Interactions
    | {
      shape: document
      style.fill: "#E8F5E9"
    }

    synthetics: Synthetics Monitors {
      shape: hexagon
      style.fill: "#4CAF50"
      style.font-color: white
    }
    synth_desc: |md
      - API tests
      - Browser tests
      - Scripted
    | {
      shape: document
      style.fill: "#E8F5E9"
    }

    otel: OpenTelemetry Collector {
      shape: hexagon
      style.fill: "#4CAF50"
      style.font-color: white
    }
    otel_desc: |md
      - OTLP traces
      - OTLP metrics
      - OTLP logs
    | {
      shape: document
      style.fill: "#E8F5E9"
    }

    mobile -> mobile_desc
    synthetics -> synth_desc
    otel -> otel_desc
  }
}
```

## Configuration

### Infrastructure Agent Configuration

```yaml
# /etc/newrelic-infra.yml
license_key: <LICENSE_KEY>
display_name: web-server-01

# Proxy configuration
proxy: https://proxy.example.com:3128

# Custom attributes
custom_attributes:
  environment: production
  team: platform
  region: us-east-1

# Logging
log:
  level: info
  file: /var/log/newrelic-infra/newrelic-infra.log

# Features
enable_process_metrics: true
metrics_process_sample_rate: 60

# Docker monitoring
docker:
  enabled: true

# Kubernetes
kubernetes:
  enabled: true
```

### APM Agent Configuration (Python)

```ini
# newrelic.ini
[newrelic]
license_key = <LICENSE_KEY>
app_name = My Python Application
monitor_mode = true

# Distributed tracing
distributed_tracing.enabled = true
span_events.enabled = true

# Transaction tracer
transaction_tracer.enabled = true
transaction_tracer.transaction_threshold = apdex_f
transaction_tracer.record_sql = obfuscated
transaction_tracer.stack_trace_threshold = 0.5

# Error collector
error_collector.enabled = true
error_collector.ignore_errors =
error_collector.ignore_status_codes = 404

# Browser monitoring
browser_monitoring.auto_instrument = true

# Custom attributes
attributes.include = request.headers.* response.headers.*
attributes.exclude = request.headers.cookie request.headers.authorization

# Logging
log_file = /var/log/newrelic/newrelic-python-agent.log
log_level = info

# High security mode
high_security = false

# Labels (tags)
labels = Environment:production;Team:platform

# Proxy
proxy_host =
proxy_port =
```

### Node.js APM Configuration

```javascript
// newrelic.js
'use strict';

exports.config = {
  app_name: ['My Node.js Application'],
  license_key: process.env.NEW_RELIC_LICENSE_KEY,

  distributed_tracing: {
    enabled: true,
  },

  transaction_tracer: {
    enabled: true,
    record_sql: 'obfuscated',
    explain_threshold: 500,
  },

  error_collector: {
    enabled: true,
    ignore_status_codes: [404],
  },

  browser_monitoring: {
    enable: true,
  },

  custom_insights_events: {
    enabled: true,
    max_samples_stored: 3000,
  },

  attributes: {
    include: ['request.headers.host', 'request.headers.user-agent'],
    exclude: ['request.headers.cookie', 'request.headers.authorization'],
  },

  logging: {
    level: 'info',
    filepath: '/var/log/newrelic/nodejs-agent.log',
  },

  labels: {
    Environment: 'production',
    Team: 'platform',
  },
};
```

## NRQL Query Language

### Basic Queries

```sql
-- Simple selection
SELECT * FROM Transaction WHERE appName = 'My App' SINCE 1 hour ago

-- Aggregation
SELECT count(*) FROM Transaction FACET name SINCE 1 day ago

-- Average response time
SELECT average(duration) FROM Transaction WHERE appName = 'My App' SINCE 1 hour ago

-- Percentiles
SELECT percentile(duration, 50, 90, 95, 99) FROM Transaction SINCE 1 hour ago

-- Error rate
SELECT percentage(count(*), WHERE error IS true) as 'Error Rate'
FROM Transaction SINCE 1 hour ago

-- Histogram
SELECT histogram(duration, 10, 20) FROM Transaction SINCE 1 hour ago

-- Time series
SELECT average(duration) FROM Transaction TIMESERIES 5 minutes SINCE 1 hour ago

-- Compare with previous period
SELECT average(duration) FROM Transaction
SINCE 1 hour ago COMPARE WITH 1 week ago

-- Filter and aggregate
SELECT count(*), average(duration) FROM Transaction
WHERE httpResponseCode >= 500 FACET name SINCE 1 day ago LIMIT 20
```

### Advanced Queries

```sql
-- Funnel analysis
SELECT funnel(session,
  WHERE pageUrl LIKE '%/home%' AS 'Home',
  WHERE pageUrl LIKE '%/products%' AS 'Products',
  WHERE pageUrl LIKE '%/cart%' AS 'Cart',
  WHERE pageUrl LIKE '%/checkout%' AS 'Checkout'
) FROM PageView SINCE 1 week ago

-- Cohort analysis
SELECT uniqueCount(userId) FROM Transaction
FACET cases(
  WHERE duration < 1 AS 'Fast',
  WHERE duration >= 1 AND duration < 3 AS 'Normal',
  WHERE duration >= 3 AS 'Slow'
) SINCE 1 day ago

-- Rate calculation
SELECT rate(count(*), 1 minute) as 'Requests per minute'
FROM Transaction SINCE 1 hour ago TIMESERIES

-- Join-like (subquery)
FROM Transaction SELECT average(duration)
WHERE name IN (
  FROM Transaction SELECT uniques(name) WHERE error IS true
) SINCE 1 hour ago

-- Extrapolate for sampling
SELECT count(*) FROM Transaction
SINCE 1 hour ago EXTRAPOLATE

-- Apdex score
SELECT apdex(duration, 0.5) FROM Transaction SINCE 1 hour ago
```

## Custom Instrumentation

### Python Custom Instrumentation

```python
import newrelic.agent

# Initialize agent
newrelic.agent.initialize('/path/to/newrelic.ini')

# Custom transaction
@newrelic.agent.background_task(name='process_order')
def process_order(order_id):
    # Add custom attribute
    newrelic.agent.add_custom_attribute('order_id', order_id)

    # Custom span
    with newrelic.agent.FunctionTrace(name='validate_order'):
        validate_order(order_id)

    # Record custom event
    newrelic.agent.record_custom_event('OrderProcessed', {
        'order_id': order_id,
        'amount': 99.99,
        'status': 'completed'
    })

    return result

# Custom metric
newrelic.agent.record_custom_metric('Custom/OrderCount', 1)

# Notice error
try:
    risky_operation()
except Exception as e:
    newrelic.agent.notice_error()
    raise
```

### Node.js Custom Instrumentation

```javascript
const newrelic = require('newrelic');

// Custom transaction
function processOrder(orderId) {
  return newrelic.startBackgroundTransaction('processOrder', () => {
    const transaction = newrelic.getTransaction();

    // Add custom attribute
    newrelic.addCustomAttribute('orderId', orderId);

    // Create custom segment
    return newrelic
      .startSegment('validateOrder', true, () => {
        return validateOrder(orderId);
      })
      .then(result => {
        // Record custom event
        newrelic.recordCustomEvent('OrderProcessed', {
          orderId: orderId,
          amount: 99.99,
          status: 'completed',
        });

        transaction.end();
        return result;
      });
  });
}

// Custom metric
newrelic.recordMetric('Custom/OrderCount', 1);

// Notice error
try {
  riskyOperation();
} catch (error) {
  newrelic.noticeError(error, { orderId: '12345' });
  throw error;
}
```

## Alerting

### NRQL Alert Conditions

```json
{
  "name": "High Error Rate",
  "type": "static",
  "nrql": {
    "query": "SELECT percentage(count(*), WHERE error IS true) FROM Transaction WHERE appName = 'My App'"
  },
  "critical": {
    "operator": "above",
    "threshold": 5,
    "thresholdDuration": 300,
    "thresholdOccurrences": "all"
  },
  "warning": {
    "operator": "above",
    "threshold": 2,
    "thresholdDuration": 300,
    "thresholdOccurrences": "all"
  },
  "runbookUrl": "https://wiki.example.com/runbooks/high-error-rate"
}
```

### Alert Condition Types

| Type           | Description            | Use Case                         |
| -------------- | ---------------------- | -------------------------------- |
| NRQL           | Query-based conditions | Custom metrics, complex logic    |
| APM            | Application conditions | Response time, error rate, Apdex |
| Infrastructure | Host conditions        | CPU, memory, disk                |
| Browser        | Page load conditions   | Page views, JS errors            |
| Synthetics     | Monitor conditions     | Uptime, response time            |
| Baseline       | ML-based anomalies     | Deviation from normal            |

## Integrations

### On-Host Integrations

```yaml
# /etc/newrelic-infra/integrations.d/nginx-config.yml
integrations:
  - name: nri-nginx
    env:
      STATUS_URL: http://127.0.0.1/status
      STATUS_MODULE: discover
      REMOTE_MONITORING: true
    interval: 30s
    labels:
      environment: production
      role: webserver
```

### Flex Integration (Custom)

```yaml
# /etc/newrelic-infra/integrations.d/my-custom-integration.yml
integrations:
  - name: nri-flex
    interval: 60s
    config:
      name: MyCustomIntegration
      apis:
        - name: MyAPI
          url: http://localhost:8080/metrics
          headers:
            Authorization: Bearer ${MY_TOKEN}
          jq: '.metrics[]'

        - name: CommandOutput
          commands:
            - run: cat /proc/meminfo | grep MemFree
              split_by: ':'
              set_header: [metric, value]
```

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Usage](usage.md) - Deployment examples and troubleshooting
