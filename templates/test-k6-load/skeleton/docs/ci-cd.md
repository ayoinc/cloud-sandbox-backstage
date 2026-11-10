# CI/CD Integration

## GitHub Actions

This project includes a GitHub Actions workflow, `.github/workflows/k6.yaml`.
It passes on a new repository with nothing configured.

### Workflow Triggers

The workflow runs on:

- Push and pull requests to `main` (validation and smoke tests)
- Manual trigger (workflow_dispatch)
- Weekly schedule, Monday 06:00 UTC

### Jobs

| Job          | Runs on               | What it does                                                                  |
| ------------ | --------------------- | ----------------------------------------------------------------------------- |
| `security`   | Push, pull request    | Trivy scan; fails on HIGH and CRITICAL findings                               |
| `smoke-test` | Every trigger         | `k6 inspect` on every script, then a 15 second, 5 VU run of each against the bundled test target |
| `load-test`  | Manual, schedule      | The full test against a deployed environment, when one is set                 |

### The bundled test target

`test-target/server.js` is a small HTTP server that answers the endpoints the
scripts call. The `smoke-test` job starts it inside the job, so the scripts
always have something to run against. To do the same locally:

```bash
node test-target/server.js &
k6 run --vus 5 --duration 15s -e BASE_URL=http://127.0.0.1:3000 scripts/load-test.js
```

### Load testing a deployed environment

Set `BASE_URL` as a repository variable (or secret) in
**Settings > Secrets and variables > Actions**. The weekly run then executes
the `${{ values.testType or "load" }}` test against it. Without it the scheduled load test is skipped.

A manual run takes the test type, virtual users, duration and target URL as
inputs. When the URL input is empty it uses `BASE_URL`, then the URL the project
was created with (`${{ values.baseUrl }}`).

## Running in CI

The `load-test` job:

- Installs k6
- Runs the selected test scenario
- Writes results to `results.json` and uploads it as the `k6-results` artifact
- Adds the run parameters to the job summary

A crossed threshold makes k6 exit non-zero, which fails the job.

## Integration with Monitoring

### Grafana Cloud k6

```bash
# Set up cloud integration
k6 cloud login --token <your-token>

# Run with cloud output
k6 cloud run scripts/load-test.js
```

### Prometheus

```bash
# Start with Prometheus Remote Write
k6 run --out experimental-prometheus-rw scripts/load-test.js
```

## Notifications

Add Slack notifications for test results:

```yaml
- name: Notify Slack
  if: failure()
  uses: slackapi/slack-github-action@v2
  with:
    webhook: {% raw %}${{ secrets.SLACK_WEBHOOK_URL }}{% endraw %}
    webhook-type: incoming-webhook
    payload: |
      {
        "text": "Load test failed! Check results at {% raw %}${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}{% endraw %}"
      }
```
