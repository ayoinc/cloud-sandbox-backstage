# ${{ values.name }}

${{ values.description }}

## Overview

This k6 load testing project provides a comprehensive performance testing suite for validating application behavior under various load conditions. The project includes:

- Pre-configured test scripts for load, stress, spike, and soak testing
- Custom metrics collection and threshold validation
- CI/CD integration with GitHub Actions
- Reusable helper functions and centralized configuration
- JSON output for integration with monitoring tools

```d2
direction: right

title: {
  label: k6 Load Testing Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

scripts: Test Scripts {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  load: load-test.js {
    style.fill: "#E8F5E9"
  }
  stress: stress-test.js {
    style.fill: "#FFF3E0"
  }
  spike: spike-test.js {
    style.fill: "#FCE4EC"
  }
  soak: soak-test.js {
    style.fill: "#F3E5F5"
  }
}

k6: k6 Engine {
  shape: hexagon
  style.fill: "#7C4DFF"
  style.stroke: "#4527A0"
  style.font-color: "#FFFFFF"

  vus: Virtual Users (${{ values.virtualUsers }} VUs) {
    shape: person
    style.fill: "#B388FF"
  }

  executor: Executor {
    style.fill: "#B388FF"
  }
}

target: Target Application {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"

  url: ${{ values.baseUrl }} {
    shape: oval
  }

  api: API Endpoints {
    shape: rectangle
  }
}

metrics: Metrics & Reporting {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  builtin: Built-in Metrics {
    label: "http_req_duration\nhttp_req_failed\niterations"
  }

  custom: Custom Metrics {
    label: "error_rate\napi_duration"
  }

  output: Output {
    shape: cylinder
    label: "JSON\nConsole\nCloud"
  }
}

scripts -> k6: executes
k6.vus -> target.url: HTTP requests
k6.executor -> k6.vus: manages
target -> metrics.builtin: collects
k6 -> metrics.custom: tracks
metrics.builtin -> metrics.output
metrics.custom -> metrics.output
```

## Configuration Summary

| Setting          | Value                                              |
| ---------------- | -------------------------------------------------- |
| Project Name     | `${{ values.name }}`                               |
| Test Type        | `${{ values.testType }}`                           |
| Virtual Users    | `${{ values.virtualUsers }}`                       |
| Test Duration    | `${{ values.duration }}`                           |
| Target URL       | `${{ values.baseUrl }}`                            |
| Owner            | `${{ values.owner }}`                              |

## Project Structure

```
.
├── scripts/                   # Test scripts directory
│   ├── load-test.js           # Standard load test scenario
│   ├── stress-test.js         # Stress test to find breaking points
│   ├── spike-test.js          # Sudden traffic spike simulation
│   ├── soak-test.js           # Long-running stability test
│   └── lib/                   # Shared utilities
│       ├── config.js          # Centralized configuration
│       └── helpers.js         # Helper functions
├── data/                      # Test data files
│   └── users.json             # Sample user data for tests
├── docs/                      # Documentation (TechDocs)
│   ├── index.md               # Main documentation
│   ├── getting-started.md     # Quick start guide
│   ├── test-scenarios.md      # Test scenario details
│   ├── thresholds.md          # Threshold configuration
│   └── ci-cd.md               # CI/CD documentation
├── .github/
│   └── workflows/
│       └── k6.yaml            # GitHub Actions workflow
├── catalog-info.yaml          # Backstage catalog registration
└── mkdocs.yml                 # TechDocs configuration
```

### Key Files

| File                    | Description                                          |
| ----------------------- | ---------------------------------------------------- |
| `scripts/load-test.js`  | Main load test with configurable VUs and duration    |
| `scripts/lib/config.js` | Centralized configuration for all test scripts       |
| `scripts/lib/helpers.js`| Reusable utility functions for API testing           |
| `.github/workflows/k6.yaml` | CI/CD pipeline for automated test execution      |

---

## CI/CD Pipeline

This repository includes a GitHub Actions workflow for automated performance testing with:

- **Manual Dispatch**: Run any test type on-demand with custom parameters
- **Scheduled Runs**: Weekly load tests for baseline monitoring
- **PR Smoke Tests**: Quick validation on pull requests
- **Artifact Storage**: Test results preserved for 30 days
- **Summary Reports**: GitHub Actions summary with key metrics

### Pipeline Workflow

```d2
direction: right

trigger: Trigger {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  manual: Manual Dispatch
  schedule: Weekly Schedule
  pr: Pull Request
}

setup: Setup {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Checkout\nInstall k6"
}

execute: Execute Tests {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  select: Select Test Type {
    shape: diamond
  }

  load: Load Test
  stress: Stress Test
  spike: Spike Test
  soak: Soak Test
}

collect: Collect Results {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
  label: "JSON Output\nMetrics"
}

report: Report {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  artifact: Upload Artifact {
    shape: cylinder
  }

  summary: GitHub Summary {
    shape: document
  }
}

trigger -> setup -> execute.select
execute.select -> execute.load: load
execute.select -> execute.stress: stress
execute.select -> execute.spike: spike
execute.select -> execute.soak: soak
execute.load -> collect
execute.stress -> collect
execute.spike -> collect
execute.soak -> collect
collect -> report.artifact
collect -> report.summary
```

### Workflow Triggers

| Trigger           | Behavior                                              |
| ----------------- | ----------------------------------------------------- |
| `workflow_dispatch` | Manual run with configurable test type, VUs, duration |
| `schedule`        | Weekly run every Monday at 6 AM UTC                   |
| `pull_request`    | Smoke test with 5 VUs for 30 seconds                  |

---

## Prerequisites

### 1. Install k6

#### macOS (Homebrew)

```bash
brew install k6
```

#### Linux (Debian/Ubuntu)

```bash
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | \
  sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

#### Windows (Chocolatey)

```powershell
choco install k6
```

#### Docker

```bash
docker pull grafana/k6
```

### 2. Verify Installation

```bash
k6 version
# Output: k6 v0.47.0 (or newer)
```

### 3. GitHub Repository Setup (for CI/CD)

#### Optional Secrets

Configure in **Settings > Secrets and variables > Actions**:

| Secret       | Description                              | Required |
| ------------ | ---------------------------------------- | -------- |
| `BASE_URL`   | Override target URL for CI runs          | No       |
| `K6_CLOUD_TOKEN` | k6 Cloud API token for cloud runs    | No       |

---

## Usage

### Running Tests Locally

#### Basic Load Test

```bash
# Run the default load test
k6 run scripts/load-test.js
```

#### Custom Parameters

```bash
# Override virtual users and duration
k6 run --vus 100 --duration 10m scripts/load-test.js

# Use environment variables
k6 run -e BASE_URL=https://staging.example.com scripts/load-test.js
k6 run -e VUS=200 -e DURATION=15m scripts/load-test.js
```

#### Run Different Test Types

```bash
# Stress test - find breaking points
k6 run scripts/stress-test.js

# Spike test - sudden traffic bursts
k6 run scripts/spike-test.js

# Soak test - long-running stability (run overnight)
k6 run scripts/soak-test.js
```

#### Output Results to File

```bash
# JSON output for analysis
k6 run --out json=results.json scripts/load-test.js

# CSV output
k6 run --out csv=results.csv scripts/load-test.js
```

### Running with Docker

```bash
# Basic run
docker run --rm -i grafana/k6 run - <scripts/load-test.js

# With mounted scripts directory
docker run --rm -v $(pwd)/scripts:/scripts grafana/k6 run /scripts/load-test.js

# With environment variables
docker run --rm \
  -v $(pwd)/scripts:/scripts \
  -e BASE_URL=https://staging.example.com \
  grafana/k6 run /scripts/load-test.js
```

### Running the Pipeline

#### Manual Execution

1. Navigate to **Actions** tab in GitHub
2. Select **k6 Load Tests** workflow
3. Click **Run workflow**
4. Configure:
   - **test_type**: `load`, `stress`, `spike`, or `soak`
   - **virtual_users**: Number of concurrent users
   - **duration**: Test duration (e.g., `5m`, `1h`)
5. Click **Run workflow**

---

## Test Types Explained

| Type        | Purpose                                | Duration    | VU Pattern             |
| ----------- | -------------------------------------- | ----------- | ---------------------- |
| **Load**    | Validate normal traffic handling       | ${{ values.duration }} | Gradual ramp up/down   |
| **Stress**  | Find system breaking points            | 30+ minutes | Progressive increase   |
| **Spike**   | Test sudden traffic bursts             | 10 minutes  | Sudden 14x spike       |
| **Soak**    | Detect memory leaks, resource issues   | 1-4 hours   | Constant load          |

### When to Use Each Test

```
Load Test    -> Continuous validation, release gates
Stress Test  -> Capacity planning, scaling decisions
Spike Test   -> Flash sale preparation, event planning
Soak Test    -> Memory leak detection, stability verification
```

---

## Test Script Examples

### Basic GET Request

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export default function() {
  const response = http.get('${{ values.baseUrl }}');
  
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  
  sleep(1);
}
```

### POST Request with JSON Body

```javascript
import http from 'k6/http';
import { check } from 'k6';

export default function() {
  const payload = JSON.stringify({
    username: 'testuser',
    email: 'test@example.com',
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const response = http.post('${{ values.baseUrl }}/api/users', payload, params);
  
  check(response, {
    'user created': (r) => r.status === 201,
  });
}
```

### Authenticated Requests

```javascript
import http from 'k6/http';
import { check } from 'k6';

export function setup() {
  // Login and get token
  const loginRes = http.post('${{ values.baseUrl }}/api/login', {
    username: 'admin',
    password: 'password',
  });
  
  return { token: loginRes.json('token') };
}

export default function(data) {
  const params = {
    headers: {
      Authorization: `Bearer ${data.token}`,
    },
  };

  const response = http.get('${{ values.baseUrl }}/api/protected', params);
  
  check(response, {
    'authenticated request successful': (r) => r.status === 200,
  });
}
```

---

## Thresholds Configuration

Thresholds define pass/fail criteria for your tests. The default thresholds are:

| Metric             | Threshold       | Description                          |
| ------------------ | --------------- | ------------------------------------ |
| `http_req_duration`| p(95) < 500ms   | 95th percentile response time        |
| `http_req_duration`| p(99) < 1500ms  | 99th percentile response time        |
| `http_req_failed`  | rate < 1%       | Error rate below 1%                  |
| `error_rate`       | rate < 5%       | Custom error rate metric             |

### Customizing Thresholds

```javascript
export const options = {
  thresholds: {
    // Response time thresholds
    http_req_duration: ['p(95)<300', 'p(99)<1000'],
    
    // Error rate thresholds
    http_req_failed: ['rate<0.005'],  // Less than 0.5%
    
    // Custom metric thresholds
    error_rate: ['rate<0.01'],
    
    // Per-endpoint thresholds
    'http_req_duration{name:health_check}': ['p(95)<100'],
    'http_req_duration{name:api_call}': ['p(95)<500'],
  },
};
```

### Threshold Behavior in CI

When thresholds are breached:
- k6 exits with a non-zero code
- GitHub Actions marks the job as failed
- Results are still uploaded as artifacts

---

## Metrics and Reporting

### Built-in Metrics

| Metric               | Type    | Description                          |
| -------------------- | ------- | ------------------------------------ |
| `http_reqs`          | Counter | Total HTTP requests made             |
| `http_req_duration`  | Trend   | Request duration (response time)     |
| `http_req_blocked`   | Trend   | Time waiting for connection          |
| `http_req_connecting`| Trend   | TCP connection time                  |
| `http_req_sending`   | Trend   | Time sending request                 |
| `http_req_receiving` | Trend   | Time receiving response              |
| `http_req_failed`    | Rate    | Failed request rate                  |
| `iterations`         | Counter | Total VU iterations                  |
| `vus`                | Gauge   | Current number of active VUs         |

### Custom Metrics

This project includes custom metrics:

```javascript
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('error_rate');
const apiDuration = new Trend('api_duration');

export default function() {
  const response = http.get(url);
  errorRate.add(response.status !== 200);
  apiDuration.add(response.timings.duration);
}
```

### Output Formats

```bash
# JSON (for programmatic analysis)
k6 run --out json=results.json scripts/load-test.js

# CSV (for spreadsheet analysis)
k6 run --out csv=results.csv scripts/load-test.js

# k6 Cloud (for hosted analysis)
k6 cloud scripts/load-test.js
```

---

## Integration with Monitoring

### Grafana Cloud k6

```bash
# Set token
export K6_CLOUD_TOKEN=your-token-here

# Run with cloud output
k6 run --out cloud scripts/load-test.js
```

### InfluxDB + Grafana

```bash
# Output to InfluxDB
k6 run --out influxdb=http://localhost:8086/k6 scripts/load-test.js
```

### Prometheus

```bash
# Start k6 with Prometheus remote write
k6 run --out experimental-prometheus-rw scripts/load-test.js
```

### Datadog

```bash
# Using xk6-output-datadog extension
k6 run --out datadog scripts/load-test.js
```

### Sample Grafana Dashboard Queries

```sql
-- Average response time
SELECT mean("value") FROM "http_req_duration" WHERE $timeFilter GROUP BY time($interval)

-- Error rate percentage
SELECT mean("value") * 100 FROM "http_req_failed" WHERE $timeFilter GROUP BY time($interval)

-- Requests per second
SELECT derivative(max("value"), 1s) FROM "http_reqs" WHERE $timeFilter GROUP BY time($interval)
```

---

## Troubleshooting

### Connection Issues

**Error: dial tcp: lookup hostname: no such host**

```bash
# Verify the target URL is accessible
curl -I ${{ values.baseUrl }}

# Check DNS resolution
nslookup $(echo ${{ values.baseUrl }} | sed 's|https*://||' | cut -d'/' -f1)
```

**Resolution:**
1. Verify the target URL is correct
2. Check network connectivity
3. Ensure the target service is running

### High Error Rate

**Error: http_req_failed threshold breached**

**Resolution:**
1. Check target service health
2. Review error logs on the target
3. Reduce VU count or increase ramp-up time
4. Verify rate limiting isn't being triggered

### Threshold Failures

**Error: thresholds on metrics have been breached**

```bash
# Run with more detailed output
k6 run --http-debug scripts/load-test.js
```

**Resolution:**
1. Analyze which specific threshold failed
2. Review response time percentiles
3. Check for slow endpoints
4. Consider adjusting thresholds for realistic expectations

### Memory Issues

**Error: FATAL: out of memory**

```bash
# Limit VUs for local testing
k6 run --vus 50 --duration 1m scripts/load-test.js
```

**Resolution:**
1. Reduce virtual user count
2. Increase system memory
3. Use k6 Cloud for large-scale tests

### Script Errors

**Error: ReferenceError: http is not defined**

```javascript
// Ensure proper imports at the top of your script
import http from 'k6/http';
import { check, sleep } from 'k6';
```

### CI/CD Pipeline Failures

**Workflow failing on install step**

**Resolution:**
1. Check GitHub Actions logs for specific errors
2. Verify k6 GPG key hasn't changed
3. Try using Docker-based execution as alternative

---

## Best Practices

### Test Design

- **Start small**: Begin with low VU counts and increase gradually
- **Use realistic data**: Load test data from files rather than hardcoding
- **Include think time**: Add `sleep()` to simulate real user behavior
- **Test incrementally**: Run smoke tests before full load tests

### Threshold Setting

- Base thresholds on production SLOs
- Use percentiles (p95, p99) rather than averages
- Set different thresholds for different endpoints
- Allow slightly higher thresholds for stress/spike tests

### CI/CD Integration

- Run smoke tests on every PR
- Schedule full load tests weekly or nightly
- Store results as artifacts for trend analysis
- Alert on threshold breaches

---

## Related Templates

| Template                                                          | Description                          |
| ----------------------------------------------------------------- | ------------------------------------ |
| [test-playwright](/docs/default/template/test-playwright)         | Playwright E2E testing suite         |
| [test-jest](/docs/default/template/test-jest)                     | Jest unit testing framework          |
| [test-cypress](/docs/default/template/test-cypress)               | Cypress E2E testing framework        |
| [observability-grafana](/docs/default/template/observability-grafana) | Grafana dashboards for metrics   |
| [service-node](/docs/default/template/service-node)               | Node.js service (target example)     |

---

## References

- [k6 Documentation](https://k6.io/docs/)
- [k6 JavaScript API](https://k6.io/docs/javascript-api/)
- [k6 Thresholds](https://k6.io/docs/using-k6/thresholds/)
- [k6 Metrics](https://k6.io/docs/using-k6/metrics/)
- [k6 Cloud](https://k6.io/docs/cloud/)
- [Grafana k6](https://grafana.com/docs/k6/latest/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Performance Testing Best Practices](https://k6.io/docs/testing-guides/load-testing-websites/)
