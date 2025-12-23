# Thresholds

## Overview

Thresholds define pass/fail criteria for your load tests. When thresholds are exceeded, k6 exits with a non-zero status, failing CI pipelines.

## Default Thresholds

This project includes the following default thresholds:

```javascript
export const options = {
  thresholds: {
    // 95% of requests should complete within 500ms
    http_req_duration: ['p(95)<500'],
    
    // Error rate should be less than 1%
    http_req_failed: ['rate<0.01'],
    
    // 99% of requests should complete within 1500ms
    'http_req_duration{status:200}': ['p(99)<1500'],
  },
};
```

## Common Threshold Metrics

### Response Time

```javascript
thresholds: {
  http_req_duration: [
    'p(95)<500',   // 95th percentile under 500ms
    'p(99)<1500',  // 99th percentile under 1500ms
    'avg<200',     // Average under 200ms
    'max<3000',    // Maximum under 3 seconds
  ],
}
```

### Error Rate

```javascript
thresholds: {
  http_req_failed: [
    'rate<0.01',   // Less than 1% errors
    'count<100',   // Less than 100 total errors
  ],
}
```

### Throughput

```javascript
thresholds: {
  http_reqs: [
    'rate>100',    // At least 100 requests per second
  ],
}
```

### Custom Metrics

```javascript
import { Rate, Trend } from 'k6/metrics';

const loginFailRate = new Rate('login_fail_rate');
const loginDuration = new Trend('login_duration');

export const options = {
  thresholds: {
    login_fail_rate: ['rate<0.05'],    // Login fails less than 5%
    login_duration: ['p(95)<1000'],    // Login completes in 1s
  },
};
```

## Threshold Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `<` | Less than | `p(95)<500` |
| `<=` | Less than or equal | `avg<=200` |
| `>` | Greater than | `rate>100` |
| `>=` | Greater than or equal | `count>=1000` |
| `==` | Equal to | `count==0` |
| `!=` | Not equal to | `count!=0` |

## Abort on Threshold Failure

Stop the test early if thresholds are exceeded:

```javascript
export const options = {
  thresholds: {
    http_req_failed: [{
      threshold: 'rate<0.01',
      abortOnFail: true,
      delayAbortEval: '10s',  // Wait 10s before checking
    }],
  },
};
```

## Environment-Specific Thresholds

Adjust thresholds based on environment:

```javascript
const isProduction = __ENV.ENVIRONMENT === 'production';

export const options = {
  thresholds: {
    http_req_duration: [
      isProduction ? 'p(95)<200' : 'p(95)<500',
    ],
  },
};
```

## Best Practices

1. **Start conservative**: Begin with relaxed thresholds, then tighten
2. **Use percentiles**: Prefer p(95) over average for response times
3. **Monitor error rates**: Always include error rate thresholds
4. **Environment-aware**: Adjust thresholds for staging vs production
5. **Document decisions**: Explain why each threshold was chosen
