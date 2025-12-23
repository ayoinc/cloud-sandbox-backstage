# CI/CD Integration

## GitHub Actions

This project includes a GitHub Actions workflow for automated load testing.

### Workflow Triggers

The workflow runs on:
- Manual trigger (workflow_dispatch)
- Scheduled runs (configurable)
- Pull requests (smoke tests only)

### Pipeline Overview

1. **Install**: Set up k6
2. **Run Tests**: Execute load tests against target environment
3. **Report**: Upload results and metrics

## Environment Variables

Configure these secrets in your GitHub repository:

| Secret | Description |
|--------|-------------|
| `BASE_URL` | Target application URL |
| `K6_CLOUD_TOKEN` | (Optional) k6 Cloud API token |

## Running in CI

The workflow automatically:
- Installs k6
- Runs the specified test scenario
- Outputs results to JSON
- Uploads artifacts

### Customizing the Pipeline

Edit `.github/workflows/k6.yaml` to:
- Change test scenarios
- Adjust virtual user counts
- Configure different environments
- Set up Grafana Cloud k6 integration

## Local CI Simulation

Test the CI configuration locally:

```bash
# Run with CI-like settings
k6 run --out json=results.json scripts/load-test.js

# Check threshold results
echo $?  # 0 = pass, non-zero = fail
```

## Integration with Monitoring

### Grafana Cloud k6

```bash
# Set up cloud integration
k6 login cloud --token <your-token>

# Run with cloud output
k6 cloud scripts/load-test.js
```

### InfluxDB + Grafana

```bash
# Output to InfluxDB
k6 run --out influxdb=http://localhost:8086/k6 scripts/load-test.js
```

### Prometheus

```bash
# Start with Prometheus Remote Write
k6 run --out experimental-prometheus-rw scripts/load-test.js
```

## Artifacts

The following artifacts are uploaded:
- `k6-results.json`: Raw test results
- `k6-summary.txt`: Human-readable summary

## Notifications

Add Slack notifications for test results:

```yaml
- name: Notify Slack
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "Load test failed! Check results at ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
      }
```
