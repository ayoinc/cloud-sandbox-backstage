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
# Run all tests
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
├── playwright.config.ts
└── package.json
```

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
