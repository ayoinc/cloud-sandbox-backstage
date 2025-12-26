# ${{ values.name }}

${{ values.description }}

## Overview

k6 load testing scripts for performance and stress testing.

## Getting Started

```bash
# Install k6
brew install k6  # macOS
# or
docker pull grafana/k6

# Run tests
k6 run tests/load.js
```

## Project Structure

```
├── tests/
│   ├── load.js       # Load test
│   ├── stress.js     # Stress test
│   └── soak.js       # Soak test
├── lib/              # Shared utilities
└── package.json
```

## Running Tests

```bash
# Basic load test
k6 run tests/load.js

# With options
k6 run --vus 50 --duration 30s tests/load.js

# Output to file
k6 run --out json=results.json tests/load.js
```

## Test Types

- **Load Test**: Normal expected load
- **Stress Test**: Beyond normal capacity
- **Soak Test**: Extended duration

## Example Script

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 10,
  duration: '30s',
};

export default function () {
  const res = http.get('https://api.example.com/');
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}
```

## License

MIT

## Author

${{ values.owner }}
