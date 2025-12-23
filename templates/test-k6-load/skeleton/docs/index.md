# ${{ values.name }}

${{ values.description }}

## Overview

This is a k6 load testing project configured with:

- **Test Type**: ${{ values.testType }}
- **Virtual Users**: ${{ values.virtualUsers }}
- **Duration**: ${{ values.duration }}
- **Target URL**: `${{ values.baseUrl }}`

## Quick Start

```bash
# Install k6 (macOS)
brew install k6

# Install k6 (Linux)
sudo apt-get update && sudo apt-get install k6

# Run the default load test
k6 run scripts/load-test.js

# Run with custom options
k6 run --vus 100 --duration 10m scripts/load-test.js

# Run with environment variables
k6 run -e BASE_URL=https://staging.example.com scripts/load-test.js
```

## Project Structure

```
.
├── scripts/                 # Test scripts
│   ├── load-test.js         # Main load test
│   ├── stress-test.js       # Stress test scenario
│   ├── spike-test.js        # Spike test scenario
│   └── soak-test.js         # Soak test scenario
├── lib/                     # Shared utilities
│   ├── config.js            # Configuration
│   └── helpers.js           # Helper functions
├── data/                    # Test data files
│   └── users.json           # Sample test data
├── docs/                    # Documentation
└── .github/workflows/       # CI/CD pipelines
```

## Test Types

| Type | Purpose | Use Case |
|------|---------|----------|
| **Load** | Validate performance under expected load | Normal traffic patterns |
| **Stress** | Find breaking points | Capacity planning |
| **Spike** | Test sudden traffic bursts | Flash sales, events |
| **Soak** | Find memory leaks over time | Long-running stability |

## Viewing Results

k6 outputs results to the terminal. For detailed analysis:

```bash
# Output JSON results
k6 run --out json=results.json scripts/load-test.js

# Use k6 Cloud (requires account)
k6 cloud scripts/load-test.js
```
