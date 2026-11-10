# CI/CD Integration

## GitHub Actions

This project includes a GitHub Actions workflow, `.github/workflows/playwright.yaml`.
It passes on a new repository with nothing configured.

### Workflow Triggers

The workflow runs on:

- Push to `main` branch
- Pull requests to `main` branch
- Manual trigger (workflow_dispatch), with an optional target URL

### Jobs

| Job            | Runs on                  | What it does                                                        |
| -------------- | ------------------------ | ------------------------------------------------------------------- |
| `security`     | Push, pull request       | Trivy scan; fails on HIGH and CRITICAL findings                     |
| `test`         | Push, pull request       | Type check, then the full suite against the bundled demo app        |
| `smoke-tests`  | Pull request             | `@smoke` tests on one browser                                       |
| `target-tests` | Push to `main`, manual   | The full suite against a deployed environment, when one is set      |

### The bundled demo app

`demo-app/server.js` is a small two-page site. With `USE_DEMO_APP=1` the
Playwright configuration starts it and points `baseURL` at it. This is what the
`test` job uses, so the tests always have something to run against:

```bash
npm run test:demo
```

### Testing a deployed environment

Set `BASE_URL` as a repository variable (or secret) in
**Settings > Secrets and variables > Actions**. From then on every push to
`main` also runs the suite against that URL in the `target-tests` job. Without
it the job is skipped.

A manual run accepts a URL as input. When the input is empty it uses `BASE_URL`,
then the URL the project was created with (`${{ values.baseUrl }}`).

### Viewing Results

- Check the Actions tab in GitHub for test results
- Download the `playwright-report` artifact for the HTML report
- Traces, screenshots and videos of failed tests are in the `test-results` artifact

## Local CI Simulation

```bash
# Type check
npm run typecheck

# Run tests with CI settings against the demo app
CI=true npm run test:demo

# Open the report
npm run report
```

## Artifacts

- `playwright-report/`: HTML test report
- `test-results/`: Traces, screenshots and videos (on failure)
