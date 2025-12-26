# Playwright E2E Tests Template

This template creates a Playwright end-to-end testing project with Page Object Model pattern and CI/CD integration.

## Overview

Playwright is a modern browser automation framework that enables reliable end-to-end testing for web applications across all modern browsers.

## Features

### Browser Support

- Chromium (Chrome, Edge)
- Firefox
- WebKit (Safari)

### Included Features

- Page Object Model structure
- Cross-browser testing
- Parallel test execution
- Screenshots and video recording
- Trace viewer for debugging
- CI/CD integration
- HTML reporting

## Configuration Options

| Parameter           | Description            | Default               |
| ------------------- | ---------------------- | --------------------- |
| `baseUrl`           | Target application URL | http://localhost:3000 |
| `browsers`          | Browsers to test       | chromium              |
| `parallelWorkers`   | Parallel test workers  | 4                     |
| `enableTracing`     | Enable trace recording | true                  |
| `enableScreenshots` | Capture on failure     | true                  |

## Getting Started

### Prerequisites

- Node.js 18+
- npm or yarn

### Installation

```bash
# Install dependencies
npm install

# Install browsers
npx playwright install
```

### Run Tests

```bash
# Run all tests
npx playwright test

# Run in headed mode
npx playwright test --headed

# Run specific test file
npx playwright test tests/login.spec.ts

# Run with specific browser
npx playwright test --project=firefox

# Debug mode
npx playwright test --debug

# Show HTML report
npx playwright show-report
```

## Project Structure

```
├── tests/
│   ├── auth/
│   │   ├── login.spec.ts
│   │   └── logout.spec.ts
│   ├── dashboard/
│   │   └── dashboard.spec.ts
│   └── e2e/
│       └── user-journey.spec.ts
├── pages/
│   ├── BasePage.ts
│   ├── LoginPage.ts
│   ├── DashboardPage.ts
│   └── index.ts
├── fixtures/
│   └── test-data.json
├── utils/
│   ├── helpers.ts
│   └── api-helpers.ts
├── playwright.config.ts
└── package.json
```

## Page Object Model

### Base Page

```typescript
// pages/BasePage.ts
import { Page } from '@playwright/test';

export class BasePage {
  constructor(protected page: Page) {}

  async navigate(path: string) {
    await this.page.goto(path);
  }

  async waitForPageLoad() {
    await this.page.waitForLoadState('networkidle');
  }
}
```

### Login Page

```typescript
// pages/LoginPage.ts
import { Page, Locator } from '@playwright/test';
import { BasePage } from './BasePage';

export class LoginPage extends BasePage {
  readonly usernameInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;

  constructor(page: Page) {
    super(page);
    this.usernameInput = page.locator('[data-testid="username"]');
    this.passwordInput = page.locator('[data-testid="password"]');
    this.submitButton = page.locator('[data-testid="login-submit"]');
  }

  async login(username: string, password: string) {
    await this.usernameInput.fill(username);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }
}
```

### Using Page Objects in Tests

```typescript
// tests/auth/login.spec.ts
import { test, expect } from '@playwright/test';
import { LoginPage } from '../../pages/LoginPage';

test.describe('Login', () => {
  test('should login with valid credentials', async ({ page }) => {
    const loginPage = new LoginPage(page);

    await loginPage.navigate('/login');
    await loginPage.login('user@example.com', 'password123');

    await expect(page).toHaveURL('/dashboard');
  });

  test('should show error for invalid credentials', async ({ page }) => {
    const loginPage = new LoginPage(page);

    await loginPage.navigate('/login');
    await loginPage.login('invalid@example.com', 'wrong');

    await expect(page.locator('.error-message')).toBeVisible();
  });
});
```

## Configuration

### playwright.config.ts

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : 4,
  reporter: [['html'], ['junit', { outputFile: 'results.xml' }]],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'mobile-chrome',
      use: { ...devices['Pixel 5'] },
    },
  ],
});
```

## Fixtures

### Custom Fixtures

```typescript
// fixtures/auth.fixture.ts
import { test as base } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';

type Fixtures = {
  loginPage: LoginPage;
  authenticatedPage: Page;
};

export const test = base.extend<Fixtures>({
  loginPage: async ({ page }, use) => {
    const loginPage = new LoginPage(page);
    await use(loginPage);
  },

  authenticatedPage: async ({ page }, use) => {
    const loginPage = new LoginPage(page);
    await loginPage.navigate('/login');
    await loginPage.login('test@example.com', 'password');
    await use(page);
  },
});
```

## API Testing

### API Helpers

```typescript
// utils/api-helpers.ts
import { APIRequestContext } from '@playwright/test';

export async function createUser(
  request: APIRequestContext,
  userData: UserData,
) {
  const response = await request.post('/api/users', {
    data: userData,
  });
  return response.json();
}
```

### API Test Example

```typescript
test('should create user via API', async ({ request }) => {
  const response = await request.post('/api/users', {
    data: {
      name: 'Test User',
      email: 'test@example.com',
    },
  });

  expect(response.ok()).toBeTruthy();
  const user = await response.json();
  expect(user.name).toBe('Test User');
});
```

## Debugging

### Trace Viewer

```bash
# View trace file
npx playwright show-trace trace.zip
```

### Debug Mode

```bash
# Run with inspector
npx playwright test --debug

# Pause on specific line
await page.pause();
```

### VS Code Extension

Install the Playwright VS Code extension for:

- Run tests from editor
- Debug with breakpoints
- Pick locators interactively

## CI/CD Integration

### GitHub Actions

```yaml
name: E2E Tests
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 18

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright browsers
        run: npx playwright install --with-deps

      - name: Run tests
        run: npx playwright test
        env:
          BASE_URL: ${{ secrets.STAGING_URL }}

      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: playwright-report/
```

## Best Practices

1. **Use data-testid attributes** - More reliable than CSS selectors
2. **Keep tests independent** - Each test should set up its own state
3. **Use Page Objects** - Maintainable and reusable code
4. **Avoid hard waits** - Use Playwright auto-waiting
5. **Run in CI** - Catch regressions early
6. **Use visual comparisons** - Screenshot testing for UI

## Related Templates

- [k6 Load Testing](../test-k6-load) - Performance testing
- [React Frontend](../react-frontend) - Frontend to test
- [Python API](../python-api) - API to test
