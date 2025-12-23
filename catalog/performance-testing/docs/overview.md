# Overview

## Architecture Deep Dive

The Performance Testing Suite provides a scalable, multi-tool framework for validating application performance under various load conditions.

### Distributed Testing Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                   Distributed Load Generation                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │                    Orchestration Layer                          │     │
│  │  ┌─────────────────────────────────────────────────────────┐   │     │
│  │  │              CI/CD Pipeline (GitHub Actions/Jenkins)     │   │     │
│  │  │  - Triggers tests on deployment                         │   │     │
│  │  │  - Manages test configuration                           │   │     │
│  │  │  - Evaluates pass/fail thresholds                       │   │     │
│  │  └─────────────────────────────────────────────────────────┘   │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                    │                                     │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │                    Load Generator Cluster                       │     │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │     │
│  │  │   Node 1    │  │   Node 2    │  │      Node N         │    │     │
│  │  │  k6/Locust  │  │  k6/Locust  │  │    k6/Locust        │    │     │
│  │  │  Workers    │  │  Workers    │  │    Workers          │    │     │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘    │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                    │                                     │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │                    Metrics Collection                           │     │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │     │
│  │  │ Prometheus  │◀─│ StatsD/     │◀─│ Test Metrics        │    │     │
│  │  │             │  │ InfluxDB    │  │ (k6/Locust)         │    │     │
│  │  └──────┬──────┘  └─────────────┘  └─────────────────────┘    │     │
│  │         │                                                       │     │
│  │         ▼                                                       │     │
│  │  ┌─────────────────────────────────────────────────────────┐   │     │
│  │  │              Grafana Dashboards                          │   │     │
│  │  │  - Real-time test progress                              │   │     │
│  │  │  - Historical comparison                                │   │     │
│  │  │  - SLO tracking                                         │   │     │
│  │  └─────────────────────────────────────────────────────────┘   │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### k6 Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        k6 Execution Model                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │                    Test Script                           │    │
│   │   import http from 'k6/http';                           │    │
│   │   export default function() { ... }                     │    │
│   └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│                              ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐    │
│   │                    k6 Engine (Go)                        │    │
│   │   ┌─────────────┐  ┌─────────────┐  ┌───────────────┐   │    │
│   │   │ JavaScript  │  │ Scheduler   │  │ Metrics       │   │    │
│   │   │ Runtime     │  │ (VU Mgmt)   │  │ Engine        │   │    │
│   │   └─────────────┘  └─────────────┘  └───────────────┘   │    │
│   └─────────────────────────────────────────────────────────┘    │
│                              │                                    │
│            ┌─────────────────┼─────────────────┐                  │
│            ▼                 ▼                 ▼                  │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────────┐        │
│   │    VU 1     │   │    VU 2     │   │      VU N       │        │
│   │ (Iteration) │   │ (Iteration) │   │   (Iteration)   │        │
│   └─────────────┘   └─────────────┘   └─────────────────┘        │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

## Configuration

### k6 Configuration

```javascript
// k6-config.js
export const options = {
  // Test stages (ramping pattern)
  stages: [
    { duration: '2m', target: 100 },   // Ramp up to 100 VUs
    { duration: '5m', target: 100 },   // Stay at 100 VUs
    { duration: '2m', target: 200 },   // Ramp up to 200 VUs
    { duration: '5m', target: 200 },   // Stay at 200 VUs
    { duration: '2m', target: 0 },     // Ramp down to 0
  ],

  // Thresholds (pass/fail criteria)
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],  // Response time
    http_req_failed: ['rate<0.01'],                  // Error rate < 1%
    http_reqs: ['rate>100'],                         // Throughput > 100 RPS
    vus: ['value>0'],                                // Active VUs
    iteration_duration: ['p(95)<2000'],              // Iteration time
  },

  // Scenarios for complex patterns
  scenarios: {
    smoke: {
      executor: 'constant-vus',
      vus: 1,
      duration: '1m',
    },
    load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '5m', target: 100 },
        { duration: '10m', target: 100 },
        { duration: '5m', target: 0 },
      ],
    },
    stress: {
      executor: 'ramping-arrival-rate',
      startRate: 10,
      timeUnit: '1s',
      preAllocatedVUs: 50,
      maxVUs: 500,
      stages: [
        { duration: '2m', target: 50 },
        { duration: '5m', target: 100 },
        { duration: '2m', target: 200 },
        { duration: '5m', target: 200 },
        { duration: '2m', target: 0 },
      ],
    },
  },

  // Output configuration
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],

  // Cloud integration (Grafana k6 Cloud)
  cloud: {
    projectID: 12345,
    name: 'My Load Test',
  },
};
```

### Locust Configuration

```python
# locustfile.py
from locust import HttpUser, task, between, events
from locust.runners import MasterRunner
import logging

class WebUser(HttpUser):
    wait_time = between(1, 3)
    host = "https://api.example.com"
    
    def on_start(self):
        """Called when a user starts."""
        self.login()
    
    def login(self):
        """Authenticate user."""
        response = self.client.post("/auth/login", json={
            "username": "testuser",
            "password": "testpass"
        })
        self.token = response.json().get("token")
        self.client.headers.update({"Authorization": f"Bearer {self.token}"})
    
    @task(3)
    def get_products(self):
        """Most common action - weight 3."""
        self.client.get("/api/products")
    
    @task(2)
    def get_product_detail(self):
        """View product detail - weight 2."""
        self.client.get("/api/products/1")
    
    @task(1)
    def add_to_cart(self):
        """Add to cart - weight 1."""
        self.client.post("/api/cart", json={"product_id": 1, "quantity": 1})

class AdminUser(HttpUser):
    wait_time = between(5, 10)
    weight = 1  # 1 admin for every 10 regular users
    
    @task
    def view_dashboard(self):
        self.client.get("/admin/dashboard")


# Custom event handlers
@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    logging.info("Test is starting")

@events.test_stop.add_listener  
def on_test_stop(environment, **kwargs):
    logging.info("Test is ending")

@events.request.add_listener
def on_request(request_type, name, response_time, response_length, **kwargs):
    if response_time > 1000:
        logging.warning(f"Slow request: {name} took {response_time}ms")
```

```ini
# locust.conf
[master]
master = true
expect-workers = 4
headless = true

[worker]
worker = true
master-host = localhost

[common]
host = https://api.example.com
users = 1000
spawn-rate = 50
run-time = 10m
html = report.html
csv = results
```

### Artillery Configuration

```yaml
# artillery.yaml
config:
  target: 'https://api.example.com'
  phases:
    - duration: 60
      arrivalRate: 5
      name: "Warm up"
    - duration: 300
      arrivalRate: 20
      rampTo: 100
      name: "Ramp up load"
    - duration: 600
      arrivalRate: 100
      name: "Sustained load"
    - duration: 60
      arrivalRate: 100
      rampTo: 0
      name: "Ramp down"

  defaults:
    headers:
      Content-Type: 'application/json'

  plugins:
    expect: {}
    metrics-by-endpoint: {}

  ensure:
    p95: 500
    maxErrorRate: 1

  variables:
    userId:
      - 1
      - 2
      - 3
      - 4
      - 5

scenarios:
  - name: "API flow"
    weight: 8
    flow:
      - post:
          url: "/auth/login"
          json:
            username: "user{{ userId }}"
            password: "password"
          capture:
            - json: "$.token"
              as: "authToken"
          expect:
            - statusCode: 200

      - get:
          url: "/api/products"
          headers:
            Authorization: "Bearer {{ authToken }}"
          expect:
            - statusCode: 200
            - hasProperty: "data"

      - think: 2

      - get:
          url: "/api/products/{{ $randomNumber(1, 100) }}"
          expect:
            - statusCode: 200

      - post:
          url: "/api/cart"
          json:
            productId: "{{ $randomNumber(1, 100) }}"
            quantity: 1
          expect:
            - statusCode: 201

  - name: "Browse only"
    weight: 2
    flow:
      - loop:
          - get:
              url: "/api/products"
          - think: 1
        count: 5
```

## Performance Thresholds

### SLO Definitions

```yaml
# slo-config.yaml
service: api-gateway
environment: production

slos:
  availability:
    target: 99.9
    window: 30d
    
  latency:
    p50:
      target: 100ms
      window: 1h
    p95:
      target: 500ms
      window: 1h
    p99:
      target: 1000ms
      window: 1h
      
  throughput:
    target: 1000rps
    window: 1m
    
  error_rate:
    target: 0.1%
    window: 1h

thresholds:
  smoke_test:
    http_req_duration: ['p(95)<200']
    http_req_failed: ['rate<0.01']
    
  load_test:
    http_req_duration: ['p(95)<500', 'p(99)<1000']
    http_req_failed: ['rate<0.01']
    http_reqs: ['rate>100']
    
  stress_test:
    http_req_duration: ['p(95)<1000']
    http_req_failed: ['rate<0.05']
    
  soak_test:
    http_req_duration: ['p(95)<500']
    http_req_failed: ['rate<0.01']
    memory_usage: ['value<80']
```

### Threshold Configuration Examples

```javascript
// k6 thresholds
export const options = {
  thresholds: {
    // HTTP request duration
    'http_req_duration': [
      'p(95)<500',     // 95% of requests under 500ms
      'p(99)<1000',    // 99% of requests under 1000ms
      'avg<200',       // Average under 200ms
      'max<3000',      // Max under 3000ms
    ],
    
    // Error rate
    'http_req_failed': [
      'rate<0.01',     // Less than 1% errors
    ],
    
    // Custom metrics
    'api_call_duration': [
      'p(95)<300',
    ],
    
    // Per-URL thresholds
    'http_req_duration{name:login}': ['p(95)<1000'],
    'http_req_duration{name:products}': ['p(95)<200'],
    
    // Checks (assertions)
    'checks': ['rate>0.99'],  // 99% of checks pass
  },
};
```

## Monitoring Integration

### Prometheus Metrics Export

```javascript
// k6 with Prometheus Remote Write
export const options = {
  // ... other options
};

// Run with: K6_PROMETHEUS_RW_SERVER_URL=http://prometheus:9090/api/v1/write k6 run script.js
```

### Grafana Dashboard Configuration

```json
{
  "dashboard": {
    "title": "k6 Performance Dashboard",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(k6_http_reqs_total[1m])",
            "legendFormat": "{{method}} {{url}}"
          }
        ]
      },
      {
        "title": "Response Time (p95)",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(k6_http_req_duration_seconds_bucket[1m]))",
            "legendFormat": "p95"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "singlestat",
        "targets": [
          {
            "expr": "sum(rate(k6_http_reqs_total{status!~'2..'}[1m])) / sum(rate(k6_http_reqs_total[1m])) * 100",
            "legendFormat": "Error %"
          }
        ]
      },
      {
        "title": "Virtual Users",
        "type": "graph",
        "targets": [
          {
            "expr": "k6_vus",
            "legendFormat": "Active VUs"
          }
        ]
      }
    ]
  }
}
```

### InfluxDB + Grafana

```bash
# Run k6 with InfluxDB output
k6 run --out influxdb=http://localhost:8086/k6 script.js

# With authentication
k6 run --out influxdb=http://user:password@localhost:8086/k6 script.js
```

## Test Data Management

```javascript
// data.js - Test data generation
import { SharedArray } from 'k6/data';
import papaparse from 'https://jslib.k6.io/papaparse/5.1.1/index.js';

// Load CSV data (shared across VUs)
const users = new SharedArray('users', function () {
  return papaparse.parse(open('./users.csv'), { header: true }).data;
});

// Generate random data
export function randomUser() {
  return users[Math.floor(Math.random() * users.length)];
}

export function randomEmail() {
  return `user${Date.now()}@example.com`;
}

export function randomProduct() {
  return {
    id: Math.floor(Math.random() * 1000),
    name: `Product ${Date.now()}`,
    price: Math.random() * 100,
  };
}
```

## Correlation and Parameterization

```javascript
// Dynamic data extraction and usage
import http from 'k6/http';
import { check } from 'k6';

export default function () {
  // Login and extract token
  const loginRes = http.post('https://api.example.com/auth/login', 
    JSON.stringify({ username: 'test', password: 'test' }),
    { headers: { 'Content-Type': 'application/json' } }
  );
  
  const token = loginRes.json('token');
  
  // Use token in subsequent requests
  const params = {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  };
  
  // Get products and extract ID
  const productsRes = http.get('https://api.example.com/products', params);
  const productId = productsRes.json('data[0].id');
  
  // Use extracted ID
  const productRes = http.get(`https://api.example.com/products/${productId}`, params);
  
  check(productRes, {
    'product retrieved': (r) => r.status === 200,
    'has name': (r) => r.json('name') !== undefined,
  });
}
```
