# Test Scenarios

## Overview

This project includes four main test scenarios, each designed for different purposes.

## Load Test

**Purpose**: Validate performance under expected normal load.

**When to use**:
- Before releases to ensure performance hasn't degraded
- Establishing performance baselines
- Regular performance regression testing

**Configuration** (`scripts/load-test.js`):
```javascript
export const options = {
  stages: [
    { duration: '2m', target: 50 },  // Ramp up
    { duration: '5m', target: 50 },  // Stay at peak
    { duration: '2m', target: 0 },   // Ramp down
  ],
};
```

**Run**:
```bash
k6 run scripts/load-test.js
```

## Stress Test

**Purpose**: Find the system's breaking point by gradually increasing load.

**When to use**:
- Capacity planning
- Understanding system limits
- Identifying bottlenecks

**Configuration** (`scripts/stress-test.js`):
```javascript
export const options = {
  stages: [
    { duration: '2m', target: 100 },   // Normal load
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },   // Beyond normal
    { duration: '5m', target: 200 },
    { duration: '2m', target: 300 },   // Breaking point
    { duration: '5m', target: 300 },
    { duration: '2m', target: 0 },     // Recovery
  ],
};
```

**Run**:
```bash
k6 run scripts/stress-test.js
```

## Spike Test

**Purpose**: Test system behavior under sudden, extreme load.

**When to use**:
- Preparing for flash sales or events
- Testing auto-scaling capabilities
- Validating graceful degradation

**Configuration** (`scripts/spike-test.js`):
```javascript
export const options = {
  stages: [
    { duration: '10s', target: 100 },  // Ramp up quickly
    { duration: '1m', target: 100 },   // Stay at peak
    { duration: '10s', target: 1000 }, // SPIKE!
    { duration: '3m', target: 1000 },  // Stay at spike
    { duration: '10s', target: 100 },  // Scale back
    { duration: '3m', target: 100 },   // Recovery
    { duration: '10s', target: 0 },    // Ramp down
  ],
};
```

**Run**:
```bash
k6 run scripts/spike-test.js
```

## Soak Test

**Purpose**: Test system stability over extended periods.

**When to use**:
- Finding memory leaks
- Identifying resource exhaustion
- Long-term stability validation

**Configuration** (`scripts/soak-test.js`):
```javascript
export const options = {
  stages: [
    { duration: '5m', target: 100 },   // Ramp up
    { duration: '4h', target: 100 },   // Stay at load for hours
    { duration: '5m', target: 0 },     // Ramp down
  ],
};
```

**Run**:
```bash
k6 run scripts/soak-test.js
```

## Custom Scenarios

Create custom scenarios by combining options:

```javascript
export const options = {
  scenarios: {
    shared_iter_scenario: {
      executor: 'shared-iterations',
      vus: 10,
      iterations: 100,
    },
    per_vu_scenario: {
      executor: 'per-vu-iterations',
      vus: 10,
      iterations: 10,
      startTime: '10s',
    },
  },
};
```

See [k6 executors documentation](https://k6.io/docs/using-k6/scenarios/executors/) for more options.
