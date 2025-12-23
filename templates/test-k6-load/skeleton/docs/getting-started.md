# Getting Started

## Prerequisites

- k6 installed ([installation guide](https://k6.io/docs/getting-started/installation/))
- Access to the target application
- Node.js (optional, for data generation)

## Installation

### macOS
```bash
brew install k6
```

### Linux (Debian/Ubuntu)
```bash
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | \
  sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

### Windows
```bash
choco install k6
# or
winget install k6
```

### Docker
```bash
docker run --rm -i grafana/k6 run - <scripts/load-test.js
```

## Running Your First Test

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd ${{ values.name }}
   ```

2. Run the default load test:
   ```bash
   k6 run scripts/load-test.js
   ```

3. View the results in the terminal output.

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `BASE_URL` | Target application URL | `${{ values.baseUrl }}` |
| `VUS` | Number of virtual users | `${{ values.virtualUsers }}` |
| `DURATION` | Test duration | `${{ values.duration }}` |

### Command Line Options

```bash
# Override virtual users
k6 run --vus 100 scripts/load-test.js

# Override duration
k6 run --duration 10m scripts/load-test.js

# Set environment variables
k6 run -e BASE_URL=https://api.example.com scripts/load-test.js

# Output to JSON
k6 run --out json=results.json scripts/load-test.js
```

## Next Steps

- Read [Test Scenarios](test-scenarios.md) to understand different test types
- Review [Thresholds](thresholds.md) for pass/fail criteria
- Check [CI/CD](ci-cd.md) for pipeline integration
