# Datadog Monitoring Integration

Comprehensive observability platform providing APM, infrastructure monitoring, log management, real user monitoring, and security monitoring with unified dashboards and alerting.

## Quick Start

```bash
# Install Datadog Agent on Linux
DD_API_KEY=<YOUR_API_KEY> DD_SITE="datadoghq.com" bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script_agent7.sh)"

# Docker Agent
docker run -d --name dd-agent \
  -e DD_API_KEY=<YOUR_API_KEY> \
  -e DD_SITE="datadoghq.com" \
  -e DD_APM_ENABLED=true \
  -e DD_LOGS_ENABLED=true \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /proc/:/host/proc/:ro \
  -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
  gcr.io/datadoghq/agent:7

# Verify agent status
docker exec -it dd-agent agent status

# Send custom metric
curl -X POST "https://api.datadoghq.com/api/v1/series" \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: <YOUR_API_KEY>" \
  -d '{
    "series": [{
      "metric": "custom.test.metric",
      "points": [['"$(date +%s)"', 100]],
      "type": "gauge",
      "tags": ["env:production"]
    }]
  }'
```

## Features

| Feature | Description | Use Case |
|---------|-------------|----------|
| **APM** | Distributed tracing and profiling | Performance optimization |
| **Infrastructure** | Host, container, cloud monitoring | Capacity planning |
| **Log Management** | Centralized logging with parsing | Troubleshooting |
| **RUM** | Real User Monitoring for web/mobile | User experience |
| **Synthetics** | API and browser testing | Uptime monitoring |
| **Security Monitoring** | SIEM and threat detection | Security compliance |
| **Network Monitoring** | NPM and DNS analytics | Network troubleshooting |
| **Database Monitoring** | Query performance insights | DB optimization |
| **Serverless** | Lambda, Functions monitoring | Serverless debugging |
| **CI Visibility** | Pipeline and test analytics | DevOps insights |

## Architecture

```d2
direction: down

title: Datadog Monitoring Architecture {
  shape: text
  near: top-center
  style.font-size: 24
}

infrastructure: Your Infrastructure {
  shape: rectangle
  style.fill: "#E8F5E9"
  
  agents: Agent Types {
    shape: rectangle
    style.fill: "#C8E6C9"
    
    host: Host Agent {
      shape: hexagon
      style.fill: "#4CAF50"
      style.font-color: white
    }
    container: Container Agent {
      shape: hexagon
      style.fill: "#4CAF50"
      style.font-color: white
    }
    k8s: K8s Agent {
      shape: hexagon
      style.fill: "#4CAF50"
      style.font-color: white
    }
    cloud: Cloud Integrations {
      shape: hexagon
      style.fill: "#4CAF50"
      style.font-color: white
    }
  }
  
  dd_agent: Datadog Agent {
    shape: rectangle
    style.fill: "#81C784"
    
    metrics: Metrics Collector
    traces: Trace Agent
    logs: Logs Agent
    profiles: Profiler
  }
}

datadog: Datadog Cloud {
  shape: rectangle
  style.fill: "#E1BEE7"
  
  platform: Platform Services {
    shape: rectangle
    style.fill: "#CE93D8"
    
    metrics_exp: Metrics Explorer {
      shape: rectangle
      style.fill: "#9C27B0"
      style.font-color: white
    }
    apm: APM Service {
      shape: rectangle
      style.fill: "#9C27B0"
      style.font-color: white
    }
    logs_exp: Logs Explorer {
      shape: rectangle
      style.fill: "#9C27B0"
      style.font-color: white
    }
    siem: Security SIEM {
      shape: rectangle
      style.fill: "#9C27B0"
      style.font-color: white
    }
  }
  
  tools: Tools {
    shape: rectangle
    style.fill: "#CE93D8"
    
    dashboards: Dashboards
    alerts: Alerts
    notebooks: Notebooks
    slos: SLOs
  }
}

users: Users {
  shape: person
  style.fill: "#E3F2FD"
}

infrastructure.agents -> infrastructure.dd_agent: collect
infrastructure.dd_agent -> datadog: HTTPS (443)
datadog.platform -> datadog.tools
datadog.tools -> users: visualize & alert
```

## Agent Components

| Component | Purpose | Port |
|-----------|---------|------|
| Core Agent | Metrics collection, orchestration | - |
| APM Agent | Trace collection | 8126 |
| Process Agent | Process/container monitoring | - |
| Trace Agent | Distributed tracing | 8126 |
| Logs Agent | Log collection and forwarding | - |
| Security Agent | Runtime security | - |

## Datadog Sites

| Site | URL | Region |
|------|-----|--------|
| US1 | datadoghq.com | US East |
| US3 | us3.datadoghq.com | US West |
| US5 | us5.datadoghq.com | US Central |
| EU1 | datadoghq.eu | EU Frankfurt |
| AP1 | ap1.datadoghq.com | Japan |
| US1-FED | ddog-gov.com | US Gov |

## Version Information

| Component | Version | Notes |
|-----------|---------|-------|
| Agent 7 | 7.50+ | Current major version |
| Agent 6 | 6.x | Legacy (Python 2) |
| Agent 5 | 5.x | Deprecated |

## Related Documentation

- [Overview](overview.md) - Configuration, integrations, and security
- [Usage](usage.md) - Deployment examples, APM setup, and troubleshooting
