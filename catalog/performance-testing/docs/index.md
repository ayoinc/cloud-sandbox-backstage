# Performance Testing Suite

Comprehensive performance testing platform with k6, Locust, and Artillery for load testing, stress testing, and performance validation.

## Quick Start

```bash
# Install k6
brew install k6

# Install Locust
pip install locust

# Install Artillery
npm install -g artillery

# Run a simple k6 test
k6 run script.js

# Run Locust test
locust -f locustfile.py --host https://api.example.com

# Run Artillery test
artillery run artillery.yaml

# Quick smoke test with k6
k6 run --vus 10 --duration 30s script.js
```

## Features

| Feature | Description | Tools |
|---------|-------------|-------|
| **Load Testing** | Simulate concurrent users | k6, Locust, Artillery |
| **Stress Testing** | Find system breaking points | k6, Locust |
| **Spike Testing** | Sudden traffic increases | k6, Artillery |
| **Soak Testing** | Extended duration tests | k6, Locust |
| **API Testing** | REST, GraphQL, gRPC | k6, Artillery |
| **Browser Testing** | Real browser simulation | k6 browser, Playwright |
| **Metrics Collection** | Real-time performance data | Prometheus, Grafana |
| **CI/CD Integration** | Automated performance gates | All tools |

## Supported Testing Tools

| Tool | Language | Best For | License |
|------|----------|----------|---------|
| **k6** | JavaScript | API load testing, scripting | AGPL-3.0 |
| **Locust** | Python | Distributed testing, Python users | MIT |
| **Artillery** | YAML/JS | Quick tests, CI/CD | MPL-2.0 |
| **Gatling** | Scala | Enterprise, high throughput | Apache 2.0 |
| **JMeter** | Java | Protocol variety, GUI | Apache 2.0 |
| **wrk** | Lua | Simple HTTP benchmarks | Apache 2.0 |
| **hey** | Go | Quick HTTP benchmarks | MIT |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Performance Testing Pipeline                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                     Test Generation                              │    │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────────┐   │    │
│  │  │ k6 Scripts    │  │ Locustfiles   │  │ Artillery YAML    │   │    │
│  │  │ (JavaScript)  │  │ (Python)      │  │ (Scenarios)       │   │    │
│  │  └───────────────┘  └───────────────┘  └───────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                    │                                     │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                     Load Generation                              │    │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────────┐   │    │
│  │  │ k6 Runner     │  │ Locust Master │  │ Artillery Engine  │   │    │
│  │  │               │  │ + Workers     │  │                   │   │    │
│  │  └───────────────┘  └───────────────┘  └───────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                    │                                     │
│                                    ▼                                     │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                     Target System                                │    │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────────┐   │    │
│  │  │ Load Balancer │  │ Application   │  │ Database          │   │    │
│  │  │               │  │ Servers       │  │                   │   │    │
│  │  └───────────────┘  └───────────────┘  └───────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                    │                                     │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                     Metrics & Reporting                          │    │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────────┐   │    │
│  │  │ Prometheus    │  │ Grafana       │  │ Test Reports      │   │    │
│  │  │ (Metrics)     │  │ (Dashboards)  │  │ (HTML/JSON)       │   │    │
│  │  └───────────────┘  └───────────────┘  └───────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Test Types

| Test Type | Purpose | Duration | Load Pattern |
|-----------|---------|----------|--------------|
| **Smoke** | Verify system works | 1-5 min | Minimal (1-5 VUs) |
| **Load** | Expected load behavior | 15-60 min | Normal (target VUs) |
| **Stress** | Find breaking point | 30-60 min | Increasing until failure |
| **Spike** | Handle sudden traffic | 10-30 min | Sudden increase/decrease |
| **Soak** | Stability over time | 4-24 hours | Constant normal load |
| **Breakpoint** | Find max capacity | Until failure | Increasing continuously |

## Key Metrics

| Metric | Description | Typical Target |
|--------|-------------|----------------|
| **Response Time (p95)** | 95th percentile latency | < 500ms |
| **Response Time (p99)** | 99th percentile latency | < 1000ms |
| **Throughput (RPS)** | Requests per second | Application specific |
| **Error Rate** | Failed requests percentage | < 1% |
| **Apdex Score** | User satisfaction index | > 0.9 |
| **TTFB** | Time to first byte | < 200ms |
| **Concurrent Users** | Simultaneous active users | Application specific |

## Version Information

| Tool | Version | Key Features |
|------|---------|--------------|
| k6 | 0.49+ | Browser testing, extensions |
| Locust | 2.24+ | Modern web UI, distributed |
| Artillery | 2.0+ | Playwright integration |
| Grafana k6 Cloud | Latest | Managed execution, analytics |

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, and thresholds
- [Usage](usage.md) - Test examples and CI/CD integration
