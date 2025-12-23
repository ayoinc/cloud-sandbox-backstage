# CI/CD Integration

## GitHub Actions

This project includes a GitHub Actions workflow for automated testing.

### Workflow Triggers

The workflow runs on:
- Push to `main` branch
- Pull requests to `main` branch
- Manual trigger (workflow_dispatch)
- Scheduled runs (optional)

### Pipeline Stages

1. **Install**: Install dependencies and Playwright browsers
2. **Test**: Run tests across configured browsers
3. **Report**: Upload test reports as artifacts

### Viewing Results

- Check the Actions tab in GitHub for test results
- Download the `playwright-report` artifact for detailed HTML report
- Failed test traces are uploaded for debugging

## Environment Variables

Configure these secrets in your GitHub repository:

| Secret | Description |
|--------|-------------|
| `BASE_URL` | Override the default base URL for CI |

## Running in CI

The workflow automatically:
- Caches npm dependencies for faster runs
- Caches Playwright browsers
- Runs tests in parallel
- Uploads reports and traces on failure

### Customizing the Pipeline

Edit `.github/workflows/playwright.yaml` to:
- Add additional test jobs
- Configure different environments
- Set up deployment gates
- Integrate with other tools

## Local CI Simulation

Test the CI configuration locally:

```bash
# Run tests with CI settings
CI=true npm test

# Generate report
npx playwright show-report
```

## Artifacts

The following artifacts are uploaded:
- `playwright-report/`: HTML test report
- `test-results/`: Traces and screenshots (on failure)
