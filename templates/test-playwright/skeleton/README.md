# ${{ values.name }}

${{ values.description }}

## Overview

Playwright end-to-end testing framework for web applications.

## Getting Started

```bash
npm install
npx playwright install
```

## Running Tests

```bash
# Run all tests against the bundled demo app (no application needed)
npm run test:demo

# Run all tests against BASE_URL (default: ${{ values.baseUrl }})
npx playwright test

# Run specific test
npx playwright test tests/example.spec.ts

# Run with UI
npx playwright test --ui

# Debug mode
npx playwright test --debug
```

## Project Structure

```
├── tests/
│   ├── example.spec.ts
│   └── fixtures/
├── pages/                  # Page objects
├── demo-app/server.js      # Small site the pipeline tests against
├── playwright.config.ts
└── package.json
```

## Pipeline

`.github/workflows/playwright.yaml` type-checks the project and runs the suite
against the bundled demo app on every push and pull request, so it passes on a
new repository with nothing configured. Set a `BASE_URL` repository variable to
also run the suite against a deployed environment. See `docs/ci-cd.md`.

## Writing Tests

```typescript
import { test, expect } from '@playwright/test';

test('homepage has title', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/My App/);
});
```

## Configuration

Edit `playwright.config.ts`:

```typescript
export default defineConfig({
  testDir: './tests',
  retries: 2,
  use: {
    baseURL: 'http://localhost:3000',
  },
});
```

## Reports

```bash
npx playwright show-report
```

## License

MIT

## Author

${{ values.owner }}
