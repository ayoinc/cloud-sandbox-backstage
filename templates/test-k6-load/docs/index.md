# k6 Load Testing Template

This template creates a k6 load testing project for performance and stress testing of APIs and web applications.

## Overview

k6 is a modern load testing tool built for developer experience. This template provides a structured project with test scenarios, thresholds, and CI/CD integration.

## Features

### Test Types
- **Load Testing** - Verify system performance under expected load
- **Stress Testing** - Find breaking points and system limits
- **Spike Testing** - Test sudden traffic surges
- **Soak Testing** - Long-running tests for memory leaks

### Included Features
- Pre-configured test scenarios
- Performance thresholds
- Custom metrics
- HTML and JSON reporting
- CI/CD integration
- Docker support

## Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `baseUrl` | Target API/app URL | http://localhost:3000 |
| `testType` | Primary test type | load |
| `virtualUsers` | Concurrent users | 50 |
| `duration` | Test duration | 5m |
| `thresholds` | Enable pass/fail thresholds | true |

## Getting Started

### Prerequisites
- k6 installed ([installation guide](https://k6.io/docs/get-started/installation/))
- Target application running

### Installation

```bash
# macOS
brew install k6

# Windows
choco install k6

# Linux
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

### Run Tests

```bash
# Run load test
k6 run tests/load.js

# Run with custom options
k6 run --vus 100 --duration 10m tests/load.js

# Run with environment variables
k6 run -e BASE_URL=https://api.example.com tests/load.js

# Generate HTML report
k6 run --out json=results.json tests/load.js
```

## Project Structure

```
├── tests/
│   ├── load.js           # Load test scenario
│   ├── stress.js         # Stress test scenario
│   ├── spike.js          # Spike test scenario
│   ├── soak.js           # Soak test scenario
│   └── smoke.js          # Quick smoke test
├── lib/
│   ├── config.js         # Shared configuration
│   ├── helpers.js        # Utility functions
│   └── checks.js         # Common checks
├── data/
│   └── users.json        # Test data
├── Dockerfile
└── package.json
```

## Test Scenarios

### Load Test
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 50 },  // Ramp up
    { duration: '5m', target: 50 },  // Stay at 50 users
    { duration: '2m', target: 0 },   // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% under 500ms
    http_req_failed: ['rate<0.01'],    // <1% errors
  },
};

export default function () {
  const res = http.get(`${__ENV.BASE_URL}/api/users`);
  
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  
  sleep(1);
}
```

### Stress Test
```javascript
export const options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '5m', target: 200 },
    { duration: '2m', target: 300 },
    { duration: '5m', target: 300 },
    { duration: '10m', target: 0 },
  ],
};
```

### Spike Test
```javascript
export const options = {
  stages: [
    { duration: '10s', target: 100 },
    { duration: '1m', target: 100 },
    { duration: '10s', target: 1400 },  // Spike!
    { duration: '3m', target: 1400 },
    { duration: '10s', target: 100 },
    { duration: '3m', target: 100 },
    { duration: '10s', target: 0 },
  ],
};
```

## Thresholds

Define pass/fail criteria for your tests:

```javascript
export const options = {
  thresholds: {
    // Response time
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    
    // Error rate
    http_req_failed: ['rate<0.01'],
    
    // Custom metrics
    'http_req_duration{name:login}': ['p(95)<1000'],
    
    // Checks pass rate
    checks: ['rate>0.99'],
  },
};
```

## Custom Metrics

```javascript
import { Counter, Trend, Rate, Gauge } from 'k6/metrics';

const myCounter = new Counter('my_counter');
const myTrend = new Trend('my_trend');
const myRate = new Rate('my_rate');
const myGauge = new Gauge('my_gauge');

export default function () {
  myCounter.add(1);
  myTrend.add(response.timings.duration);
  myRate.add(response.status === 200);
  myGauge.add(response.body.length);
}
```

## Authentication

### Bearer Token
```javascript
const params = {
  headers: {
    'Authorization': `Bearer ${__ENV.API_TOKEN}`,
    'Content-Type': 'application/json',
  },
};

http.get(url, params);
```

### Login Flow
```javascript
export function setup() {
  const loginRes = http.post(`${BASE_URL}/auth/login`, JSON.stringify({
    username: 'test',
    password: 'password',
  }), { headers: { 'Content-Type': 'application/json' } });
  
  return { token: loginRes.json('token') };
}

export default function (data) {
  const params = {
    headers: { 'Authorization': `Bearer ${data.token}` },
  };
  
  http.get(`${BASE_URL}/api/protected`, params);
}
```

## Reporting

### Console Summary
Built-in summary after each test run.

### JSON Output
```bash
k6 run --out json=results.json tests/load.js
```

### InfluxDB + Grafana
```bash
k6 run --out influxdb=http://localhost:8086/k6 tests/load.js
```

### Cloud Reporting
```bash
k6 cloud tests/load.js
```

## CI/CD Integration

### GitHub Actions
```yaml
name: Load Tests
on:
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM
  workflow_dispatch:

jobs:
  load-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install k6
        run: |
          curl -L https://github.com/grafana/k6/releases/download/v0.47.0/k6-v0.47.0-linux-amd64.tar.gz | tar xvz
          sudo mv k6-v0.47.0-linux-amd64/k6 /usr/local/bin/
      
      - name: Run load test
        run: k6 run tests/load.js
        env:
          BASE_URL: ${{ secrets.TEST_API_URL }}
```

### Docker
```bash
docker run --rm -v $(pwd):/scripts grafana/k6 run /scripts/tests/load.js
```

## Best Practices

1. **Start small** - Begin with smoke tests before load tests
2. **Use realistic scenarios** - Model actual user behavior
3. **Set meaningful thresholds** - Based on SLAs and SLOs
4. **Test in staging** - Mirror production environment
5. **Monitor system metrics** - CPU, memory, DB connections
6. **Run regularly** - Catch regressions early

## Related Templates

- [Playwright E2E Tests](../test-playwright) - End-to-end testing
- [Python API](../python-api) - API to test
- [Kubernetes Microservice](../kubernetes-microservice) - Services to test
