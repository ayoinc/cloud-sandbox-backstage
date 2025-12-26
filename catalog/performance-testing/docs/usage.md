# Usage Guide

## Docker Compose Deployment

### Performance Testing Stack

```yaml
# docker-compose.yaml
version: '3.8'

services:
  k6:
    image: grafana/k6:0.49.0
    container_name: k6
    volumes:
      - ./scripts:/scripts
      - ./results:/results
    environment:
      K6_OUT: influxdb=http://influxdb:8086/k6
    command: run /scripts/load-test.js
    networks:
      - perftest-net
    depends_on:
      - influxdb

  locust-master:
    image: locustio/locust:2.24.0
    container_name: locust-master
    ports:
      - '8089:8089'
    volumes:
      - ./locust:/mnt/locust
    command: -f /mnt/locust/locustfile.py --master
    networks:
      - perftest-net

  locust-worker:
    image: locustio/locust:2.24.0
    volumes:
      - ./locust:/mnt/locust
    command: -f /mnt/locust/locustfile.py --worker --master-host locust-master
    networks:
      - perftest-net
    deploy:
      replicas: 4

  influxdb:
    image: influxdb:2.7
    container_name: influxdb
    ports:
      - '8086:8086'
    volumes:
      - influxdb-data:/var/lib/influxdb2
    environment:
      DOCKER_INFLUXDB_INIT_MODE: setup
      DOCKER_INFLUXDB_INIT_USERNAME: admin
      DOCKER_INFLUXDB_INIT_PASSWORD: adminpassword
      DOCKER_INFLUXDB_INIT_ORG: perftest
      DOCKER_INFLUXDB_INIT_BUCKET: k6
    networks:
      - perftest-net

  grafana:
    image: grafana/grafana:10.3.0
    container_name: grafana
    ports:
      - '3000:3000'
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana/datasources:/etc/grafana/provisioning/datasources
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
      GF_INSTALL_PLUGINS: grafana-k6-app
    networks:
      - perftest-net
    depends_on:
      - influxdb

volumes:
  influxdb-data:
  grafana-data:

networks:
  perftest-net:
    driver: bridge
```

## Kubernetes Deployment

### k6 Operator

```bash
# Install k6 Operator
kubectl apply -f https://github.com/grafana/k6-operator/releases/download/v0.0.14/bundle.yaml

# Create namespace
kubectl create namespace k6
```

```yaml
# k6-test.yaml
apiVersion: k6.io/v1alpha1
kind: K6
metadata:
  name: load-test
  namespace: k6
spec:
  parallelism: 4
  script:
    configMap:
      name: k6-test-script
      file: script.js
  arguments: --out influxdb=http://influxdb.monitoring:8086/k6
  runner:
    image: grafana/k6:0.49.0
    resources:
      requests:
        cpu: 500m
        memory: 512Mi
      limits:
        cpu: 1000m
        memory: 1Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: k6-test-script
  namespace: k6
data:
  script.js: |
    import http from 'k6/http';
    import { check, sleep } from 'k6';

    export const options = {
      stages: [
        { duration: '2m', target: 100 },
        { duration: '5m', target: 100 },
        { duration: '2m', target: 0 },
      ],
      thresholds: {
        http_req_duration: ['p(95)<500'],
        http_req_failed: ['rate<0.01'],
      },
    };

    export default function () {
      const res = http.get('http://target-service.default.svc.cluster.local/api/health');
      check(res, { 'status is 200': (r) => r.status === 200 });
      sleep(1);
    }
```

### Locust on Kubernetes

```yaml
# locust-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: locust-master
  namespace: perftest
spec:
  replicas: 1
  selector:
    matchLabels:
      app: locust
      role: master
  template:
    metadata:
      labels:
        app: locust
        role: master
    spec:
      containers:
        - name: locust
          image: locustio/locust:2.24.0
          ports:
            - containerPort: 8089
            - containerPort: 5557
          command:
            - locust
            - -f
            - /mnt/locust/locustfile.py
            - --master
          volumeMounts:
            - name: locust-scripts
              mountPath: /mnt/locust
      volumes:
        - name: locust-scripts
          configMap:
            name: locust-scripts
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: locust-worker
  namespace: perftest
spec:
  replicas: 10
  selector:
    matchLabels:
      app: locust
      role: worker
  template:
    metadata:
      labels:
        app: locust
        role: worker
    spec:
      containers:
        - name: locust
          image: locustio/locust:2.24.0
          command:
            - locust
            - -f
            - /mnt/locust/locustfile.py
            - --worker
            - --master-host=locust-master
          resources:
            requests:
              cpu: 500m
              memory: 256Mi
            limits:
              cpu: 1000m
              memory: 512Mi
          volumeMounts:
            - name: locust-scripts
              mountPath: /mnt/locust
      volumes:
        - name: locust-scripts
          configMap:
            name: locust-scripts
---
apiVersion: v1
kind: Service
metadata:
  name: locust-master
  namespace: perftest
spec:
  ports:
    - port: 8089
      name: web
    - port: 5557
      name: communication
  selector:
    app: locust
    role: master
```

## CI/CD Integration Examples

### GitHub Actions

```yaml
# .github/workflows/performance.yaml
name: Performance Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * *' # Daily at 2 AM

jobs:
  smoke-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run k6 Smoke Test
        uses: grafana/k6-action@v0.3.1
        with:
          filename: tests/performance/smoke.js
          flags: --out json=results.json

      - name: Upload Results
        uses: actions/upload-artifact@v4
        with:
          name: k6-smoke-results
          path: results.json

  load-test:
    runs-on: ubuntu-latest
    needs: smoke-test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Run k6 Load Test
        uses: grafana/k6-action@v0.3.1
        with:
          filename: tests/performance/load.js
          flags: --out cloud
        env:
          K6_CLOUD_TOKEN: ${{ secrets.K6_CLOUD_TOKEN }}
          K6_CLOUD_PROJECT_ID: ${{ secrets.K6_CLOUD_PROJECT_ID }}

      - name: Check Thresholds
        run: |
          if [ -f summary.json ]; then
            PASSED=$(jq '.root_group.checks | map(select(.passes > 0)) | length' summary.json)
            TOTAL=$(jq '.root_group.checks | length' summary.json)
            echo "Checks passed: $PASSED / $TOTAL"
          fi

  stress-test:
    runs-on: ubuntu-latest
    needs: load-test
    if: github.event_name == 'schedule'
    steps:
      - uses: actions/checkout@v4

      - name: Run k6 Stress Test
        uses: grafana/k6-action@v0.3.1
        with:
          filename: tests/performance/stress.js
        continue-on-error: true

      - name: Upload Stress Test Report
        uses: actions/upload-artifact@v4
        with:
          name: stress-test-results
          path: results/
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - smoke
  - load
  - stress
  - report

variables:
  K6_VERSION: '0.49.0'

.k6-template:
  image: grafana/k6:${K6_VERSION}
  before_script:
    - k6 version

smoke-test:
  extends: .k6-template
  stage: smoke
  script:
    - k6 run --out json=smoke-results.json tests/smoke.js
  artifacts:
    paths:
      - smoke-results.json
    expire_in: 1 week

load-test:
  extends: .k6-template
  stage: load
  script:
    - k6 run
      --out influxdb=http://${INFLUXDB_HOST}:8086/k6
      --tag testid=${CI_PIPELINE_ID}
      tests/load.js
  only:
    - main
    - develop
  artifacts:
    reports:
      performance: load-results.json

stress-test:
  extends: .k6-template
  stage: stress
  script:
    - k6 run tests/stress.js
  only:
    - schedules
  allow_failure: true

locust-test:
  stage: load
  image: locustio/locust:2.24.0
  script:
    - locust -f tests/locustfile.py
      --headless
      --users 100
      --spawn-rate 10
      --run-time 5m
      --host ${TARGET_URL}
      --html report.html
  artifacts:
    paths:
      - report.html

generate-report:
  stage: report
  image: python:3.11
  script:
    - pip install jinja2
    - python scripts/generate-report.py
  artifacts:
    paths:
      - performance-report.html
```

### Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any

    environment {
        K6_CLOUD_TOKEN = credentials('k6-cloud-token')
        TARGET_URL = 'https://staging.example.com'
    }

    stages {
        stage('Smoke Test') {
            steps {
                sh '''
                    docker run --rm \
                        -v ${WORKSPACE}/tests:/tests \
                        grafana/k6:0.49.0 run \
                        --out json=/tests/smoke-results.json \
                        /tests/smoke.js
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'tests/smoke-results.json'
                }
            }
        }

        stage('Load Test') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    docker run --rm \
                        -e K6_CLOUD_TOKEN=${K6_CLOUD_TOKEN} \
                        -v ${WORKSPACE}/tests:/tests \
                        grafana/k6:0.49.0 run \
                        --out cloud \
                        /tests/load.js
                '''
            }
        }

        stage('Performance Gate') {
            steps {
                script {
                    def results = readJSON file: 'tests/smoke-results.json'
                    def p95 = results.metrics.http_req_duration.values['p(95)']

                    if (p95 > 500) {
                        error "Performance threshold exceeded: p95=${p95}ms > 500ms"
                    }
                }
            }
        }
    }

    post {
        always {
            publishHTML target: [
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'reports',
                reportFiles: 'performance-report.html',
                reportName: 'Performance Report'
            ]
        }
    }
}
```

## Complete Test Scripts

### k6 Load Test

```javascript
// tests/load.js
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';
import { htmlReport } from 'https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.2/index.js';

// Custom metrics
const errorRate = new Rate('errors');
const apiDuration = new Trend('api_duration');
const successfulLogins = new Counter('successful_logins');

export const options = {
  stages: [
    { duration: '2m', target: 50 }, // Ramp up
    { duration: '5m', target: 50 }, // Stay at 50 users
    { duration: '2m', target: 100 }, // Ramp to 100
    { duration: '5m', target: 100 }, // Stay at 100
    { duration: '2m', target: 0 }, // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
    errors: ['rate<0.05'],
    api_duration: ['p(95)<300'],
  },
};

const BASE_URL = __ENV.TARGET_URL || 'https://api.example.com';

export function setup() {
  // Setup code - runs once before test
  const loginRes = http.post(
    `${BASE_URL}/auth/login`,
    JSON.stringify({
      username: 'admin',
      password: 'adminpass',
    }),
    { headers: { 'Content-Type': 'application/json' } },
  );

  return { token: loginRes.json('token') };
}

export default function (data) {
  const params = {
    headers: {
      Authorization: `Bearer ${data.token}`,
      'Content-Type': 'application/json',
    },
  };

  group('User Flow', function () {
    // Login
    group('Login', function () {
      const loginStart = Date.now();
      const loginRes = http.post(
        `${BASE_URL}/auth/login`,
        JSON.stringify({
          username: `user${__VU}`,
          password: 'password',
        }),
        { headers: { 'Content-Type': 'application/json' } },
      );

      const loginSuccess = check(loginRes, {
        'login successful': r => r.status === 200,
        'has token': r => r.json('token') !== undefined,
      });

      if (loginSuccess) {
        successfulLogins.add(1);
      }
      errorRate.add(!loginSuccess);
      apiDuration.add(Date.now() - loginStart);
    });

    sleep(1);

    // Browse Products
    group('Browse Products', function () {
      const productsRes = http.get(`${BASE_URL}/api/products`, params);

      check(productsRes, {
        'products loaded': r => r.status === 200,
        'has products': r => r.json('data.length') > 0,
      });

      errorRate.add(productsRes.status !== 200);
    });

    sleep(2);

    // View Product Detail
    group('View Product', function () {
      const productId = Math.floor(Math.random() * 100) + 1;
      const productRes = http.get(
        `${BASE_URL}/api/products/${productId}`,
        params,
      );

      check(productRes, {
        'product loaded': r => r.status === 200,
      });
    });

    sleep(1);

    // Add to Cart
    group('Add to Cart', function () {
      const cartRes = http.post(
        `${BASE_URL}/api/cart`,
        JSON.stringify({
          productId: Math.floor(Math.random() * 100) + 1,
          quantity: 1,
        }),
        params,
      );

      check(cartRes, {
        'added to cart': r => r.status === 201 || r.status === 200,
      });
    });
  });

  sleep(3);
}

export function teardown(data) {
  // Cleanup code - runs once after test
  console.log('Test completed');
}

export function handleSummary(data) {
  return {
    'results/summary.html': htmlReport(data),
    'results/summary.json': JSON.stringify(data),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}
```

### Locust Test

```python
# tests/locustfile.py
from locust import HttpUser, task, between, tag, events
from locust.runners import MasterRunner
import random
import json
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class APIUser(HttpUser):
    """Simulates typical API user behavior."""

    wait_time = between(1, 3)

    def on_start(self):
        """Login when user starts."""
        response = self.client.post("/auth/login", json={
            "username": f"user{random.randint(1, 1000)}",
            "password": "password"
        })
        if response.status_code == 200:
            self.token = response.json().get("token")
            self.client.headers.update({
                "Authorization": f"Bearer {self.token}"
            })
        else:
            logger.warning(f"Login failed: {response.status_code}")

    @tag('browse')
    @task(5)
    def browse_products(self):
        """Browse product catalog - most common action."""
        with self.client.get("/api/products", catch_response=True) as response:
            if response.status_code == 200:
                products = response.json().get("data", [])
                if len(products) == 0:
                    response.failure("No products returned")
            else:
                response.failure(f"Status: {response.status_code}")

    @tag('browse')
    @task(3)
    def view_product(self):
        """View individual product."""
        product_id = random.randint(1, 100)
        self.client.get(f"/api/products/{product_id}")

    @tag('cart')
    @task(2)
    def add_to_cart(self):
        """Add product to cart."""
        self.client.post("/api/cart", json={
            "productId": random.randint(1, 100),
            "quantity": random.randint(1, 3)
        })

    @tag('cart')
    @task(1)
    def view_cart(self):
        """View shopping cart."""
        self.client.get("/api/cart")

    @tag('checkout')
    @task(1)
    def checkout(self):
        """Complete checkout process."""
        with self.client.post("/api/checkout", json={
            "paymentMethod": "card",
            "shippingAddress": {
                "street": "123 Test St",
                "city": "Test City",
                "zip": "12345"
            }
        }, catch_response=True) as response:
            if response.status_code not in [200, 201]:
                response.failure(f"Checkout failed: {response.status_code}")


class AdminUser(HttpUser):
    """Simulates admin user behavior."""

    weight = 1  # 1 admin per 10 regular users
    wait_time = between(5, 10)

    def on_start(self):
        response = self.client.post("/auth/login", json={
            "username": "admin",
            "password": "adminpass"
        })
        if response.status_code == 200:
            self.token = response.json().get("token")
            self.client.headers.update({
                "Authorization": f"Bearer {self.token}"
            })

    @task(3)
    def view_dashboard(self):
        self.client.get("/admin/dashboard")

    @task(2)
    def view_orders(self):
        self.client.get("/admin/orders")

    @task(1)
    def view_analytics(self):
        self.client.get("/admin/analytics")


# Event handlers for custom metrics
@events.request.add_listener
def on_request(request_type, name, response_time, response_length, exception, **kwargs):
    if response_time > 1000:
        logger.warning(f"Slow request: {name} - {response_time}ms")


@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    logger.info("Performance test starting")
    if isinstance(environment.runner, MasterRunner):
        logger.info(f"Master node with {environment.runner.worker_count} workers")


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    logger.info("Performance test completed")
```

### Artillery Test

```yaml
# tests/artillery.yaml
config:
  target: '{{ $processEnvironment.TARGET_URL }}'
  phases:
    - duration: 60
      arrivalRate: 5
      name: 'Warm up'
    - duration: 120
      arrivalRate: 10
      rampTo: 50
      name: 'Ramp up'
    - duration: 300
      arrivalRate: 50
      name: 'Sustained load'
    - duration: 60
      arrivalRate: 50
      rampTo: 0
      name: 'Ramp down'

  defaults:
    headers:
      Content-Type: 'application/json'
      User-Agent: 'Artillery/2.0'

  plugins:
    expect: {}
    metrics-by-endpoint: {}

  processor: './helpers.js'

  ensure:
    p99: 1000
    p95: 500
    maxErrorRate: 1

  variables:
    products:
      - id: 1
      - id: 2
      - id: 3

scenarios:
  - name: 'Complete User Journey'
    weight: 7
    flow:
      # Login
      - post:
          url: '/auth/login'
          json:
            username: 'testuser'
            password: 'password'
          capture:
            - json: '$.token'
              as: 'authToken'
          expect:
            - statusCode: 200
            - hasProperty: 'token'

      - think: 2

      # Browse Products
      - get:
          url: '/api/products'
          headers:
            Authorization: 'Bearer {{ authToken }}'
          capture:
            - json: '$.data[0].id'
              as: 'productId'
          expect:
            - statusCode: 200

      - think: 3

      # View Product
      - get:
          url: '/api/products/{{ productId }}'
          headers:
            Authorization: 'Bearer {{ authToken }}'
          expect:
            - statusCode: 200

      - think: 2

      # Add to Cart
      - post:
          url: '/api/cart'
          headers:
            Authorization: 'Bearer {{ authToken }}'
          json:
            productId: '{{ productId }}'
            quantity: 1
          expect:
            - statusCode: [200, 201]

      - think: 1

      # Checkout
      - post:
          url: '/api/checkout'
          headers:
            Authorization: 'Bearer {{ authToken }}'
          beforeRequest: 'generateCheckoutData'
          expect:
            - statusCode: [200, 201]

  - name: 'Browse Only'
    weight: 3
    flow:
      - loop:
          - get:
              url: '/api/products'
          - think: 2
          - get:
              url: '/api/products/{{ $randomNumber(1, 100) }}'
          - think: 3
        count: 5
```

## Troubleshooting

| Issue                        | Cause                         | Solution                          |
| ---------------------------- | ----------------------------- | --------------------------------- |
| Low RPS despite high VUs     | Slow think time or bottleneck | Reduce sleep, check target system |
| Connection refused           | Target overloaded             | Reduce load, scale target         |
| High error rate              | Application errors            | Check logs, verify endpoints      |
| Memory issues in k6          | Large response bodies         | Use `discardResponseBodies`       |
| Locust workers disconnecting | Network issues                | Check master-worker connectivity  |
| Inconsistent results         | Noisy environment             | Run multiple iterations           |
| Thresholds not evaluated     | Wrong metric names            | Verify metric names in output     |
| Results not showing          | Output not configured         | Add `--out` flag                  |

### Debug Commands

```bash
# k6 verbose output
k6 run --verbose script.js

# Locust debug logging
locust -f locustfile.py --loglevel DEBUG

# Artillery debug
DEBUG=artillery:* artillery run test.yaml

# Check k6 metrics
k6 run --out json=results.json script.js
jq '.metrics' results.json
```

## Best Practices

1. **Start with smoke tests** - Verify basic functionality before load
2. **Use realistic data** - Match production patterns
3. **Ramp gradually** - Avoid sudden spikes unless testing for them
4. **Set thresholds** - Define pass/fail criteria upfront
5. **Monitor target system** - Correlate test results with system metrics
6. **Run from multiple locations** - For geographic distribution
7. **Use think times** - Simulate real user behavior
8. **Parameterize tests** - Avoid caching effects
9. **Document baselines** - Track performance over time
10. **Automate in CI/CD** - Catch regressions early
