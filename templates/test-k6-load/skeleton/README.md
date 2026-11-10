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

# Run the load test against ${{ values.baseUrl }}
k6 run scripts/load-test.js

# Try the scripts without a deployed application
node test-target/server.js &
k6 run --vus 5 --duration 15s -e BASE_URL=http://127.0.0.1:3000 scripts/load-test.js
```

## Project Structure

```
├── scripts/
│   ├── load-test.js      # Load test
│   ├── stress-test.js    # Stress test
│   ├── spike-test.js     # Spike test
│   ├── soak-test.js      # Soak test
│   └── lib/              # Shared configuration and helpers
├── test-target/server.js # Small HTTP target for smoke runs
└── data/                 # Test data
```

## Running Tests

```bash
# Basic load test
k6 run scripts/load-test.js

# Other target, virtual users and duration
k6 run -e BASE_URL=https://staging.example.com -e VUS=100 -e DURATION=10m scripts/load-test.js

# Do not fail the run on crossed thresholds
k6 run -e THRESHOLDS=false scripts/load-test.js

# Output to file
k6 run --out json=results.json scripts/load-test.js
```

## Test Types

- **Load Test**: Normal expected load (${{ values.virtualUsers }} VUs for ${{ values.duration }})
- **Stress Test**: Up to four times the normal load
- **Spike Test**: Sudden jump to fourteen times the normal load
- **Soak Test**: Normal load for an extended duration

## Pipeline

`.github/workflows/k6.yaml` inspects every script and smoke-runs it against the
bundled test target on every push and pull request, so it passes on a new
repository with nothing configured. Set a `BASE_URL` repository variable to
enable the weekly load test against a deployed environment. See `docs/ci-cd.md`.

## License

MIT

## Author

${{ values.owner }}
