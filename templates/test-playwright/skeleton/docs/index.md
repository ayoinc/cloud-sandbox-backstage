# ${{ values.name }}

${{ values.description }}

## Overview

This Playwright end-to-end testing project provides a production-ready testing framework with:

- **Page Object Model (POM)** for maintainable and reusable test code
- **Multi-browser support**: {% for browser in values.browsers %}{{ browser }}{% if not loop.last %}, {% endif %}{% endfor %}
- **Parallel execution** with ${{ values.parallelWorkers }} workers for faster test runs
- **CI/CD integration** with GitHub Actions for automated testing
- **Built-in reporting** with HTML reports, traces, and screenshots
- **Mobile viewport testing** for responsive design validation

```d2
direction: down

title: {
  label: Playwright Test Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

tests: Test Specs {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  example: example.spec.ts
  smoke: smoke.spec.ts
  e2e: e2e.spec.ts
}

fixtures: Fixtures {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  base: base.ts {
    label: "Custom Fixtures\nAuthentication\nTest Data"
  }
}

pages: Page Objects {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  basePage: BasePage.ts
  homePage: HomePage.ts
  loginPage: LoginPage.ts
}

config: Configuration {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"

  playwright: playwright.config.ts {
    label: "Browsers\nTimeouts\nReporters"
  }
}

browsers: Browsers {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"

  chromium: Chromium
  firefox: Firefox
  webkit: WebKit
  mobile: Mobile Viewports
}

reports: Reports {
  shape: cylinder
  style.fill: "#ECEFF1"
  style.stroke: "#546E7A"
  label: "HTML Report\nTraces\nScreenshots"
}

tests -> fixtures: uses
tests -> pages: interacts with
fixtures -> pages: initializes
config -> browsers: configures
tests -> browsers: runs on
browsers -> reports: generates
```

## Configuration Summary

| Setting           | Value                                                                                    |
| ----------------- | ---------------------------------------------------------------------------------------- |
| Project Name      | `${{ values.name }}`                                                                     |
| Base URL          | `${{ values.baseUrl }}`                                                                  |
| Parallel Workers  | ${{ values.parallelWorkers }}                                                            |
| Browsers          | {% for browser in values.browsers %}{{ browser }}{% if not loop.last %}, {% endif %}{% endfor %} |
| Tracing           | ${{ values.enableTracing }}                                                              |
| Screenshots       | ${{ values.enableScreenshots }}                                                          |
| Test Directory    | `./tests`                                                                                |
| Report Directory  | `./playwright-report`                                                                    |

## Project Structure

```
${{ values.name }}/
├── .github/
│   └── workflows/
│       └── playwright.yaml    # CI/CD pipeline configuration
├── docs/                      # Documentation (TechDocs)
│   └── index.md
├── pages/                     # Page Object Models
│   └── BasePage.ts            # Base page class with common utilities
├── tests/                     # Test specifications
│   ├── fixtures/              # Custom test fixtures
│   │   └── base.ts            # Extended test fixtures
│   └── example.spec.ts        # Example test file
├── playwright-report/         # Generated HTML reports (gitignored)
├── test-results/              # Test artifacts (gitignored)
├── catalog-info.yaml          # Backstage entity definition
├── mkdocs.yml                 # TechDocs configuration
├── package.json               # Dependencies and scripts
├── playwright.config.ts       # Playwright configuration
└── tsconfig.json              # TypeScript configuration
```

| Directory/File         | Purpose                                                |
| ---------------------- | ------------------------------------------------------ |
| `pages/`               | Page Object Model classes for UI interactions          |
| `tests/`               | Test specification files                               |
| `tests/fixtures/`      | Custom fixtures for authentication, data setup, etc.   |
| `playwright.config.ts` | Browser configuration, timeouts, reporters, base URL   |
| `playwright-report/`   | HTML test reports generated after each run             |
| `test-results/`        | Screenshots, videos, and traces from failed tests      |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Automatic Test Runs**: Triggered on push and pull requests to `main`
- **Multi-Browser Testing**: Full test suite runs across all configured browsers
- **Smoke Tests**: Quick validation on pull requests using `@smoke` tagged tests
- **Artifact Storage**: Test reports and failure artifacts retained for debugging
- **Environment Variables**: Configurable base URL via secrets

### Pipeline Workflow

```d2
direction: right

trigger: Trigger {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Push/PR\nto main"
}

checkout: Checkout {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Clone\nRepository"
}

setup: Setup {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Node.js 20\nnpm ci"
}

browsers: Install Browsers {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  label: "Chromium\nFirefox\nWebKit"
}

test: Run Tests {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Playwright\nTest Suite"
}

report: Upload Report {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  label: "HTML Report\nArtifacts"
}

result: Result {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Pass/Fail"
}

trigger -> checkout -> setup -> browsers -> test -> result
result -> report: always
```

### Workflow Jobs

| Job           | Trigger          | Description                                  | Timeout |
| ------------- | ---------------- | -------------------------------------------- | ------- |
| `test`        | Push/PR to main  | Full test suite across all browsers          | 30 min  |
| `smoke-tests` | Pull Request     | Quick `@smoke` tagged tests on Chromium only | 15 min  |

### Artifacts

| Artifact           | Condition | Retention | Contents                              |
| ------------------ | --------- | --------- | ------------------------------------- |
| `playwright-report`| Always    | 30 days   | HTML test report with results         |
| `test-results`     | On Failure| 7 days    | Screenshots, videos, traces           |
| `smoke-test-report`| On Failure| 7 days    | Smoke test HTML report                |

---

## Prerequisites

### 1. Node.js

Node.js 18.0.0 or higher is required.

```bash
# Check Node.js version
node --version

# Install Node.js via nvm (recommended)
nvm install 20
nvm use 20
```

### 2. Playwright Browsers

Playwright requires browser binaries to be installed:

```bash
# Install all browsers with system dependencies
npx playwright install --with-deps

# Install specific browsers only
npx playwright install chromium
npx playwright install firefox
npx playwright install webkit
```

### 3. Environment Variables

| Variable   | Description                          | Default                |
| ---------- | ------------------------------------ | ---------------------- |
| `BASE_URL` | Target application URL               | `${{ values.baseUrl }}`|
| `CI`       | Enables CI-specific behavior         | Auto-detected          |

### 4. GitHub Repository Setup (for CI/CD)

#### Required Secrets

Configure in **Settings > Secrets and variables > Actions**:

| Secret     | Description                  | Required |
| ---------- | ---------------------------- | -------- |
| `BASE_URL` | Target application URL       | Optional |

---

## Usage

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Install dependencies
npm install

# Install Playwright browsers
npx playwright install --with-deps
```

### Running Tests

```bash
# Run all tests (headless)
npm test

# Run tests with UI mode (interactive)
npm run test:ui

# Run tests in headed mode (see browser)
npm run test:headed

# Run tests in debug mode
npm run test:debug

# Run tests with code generation
npm run codegen
```

### Browser-Specific Tests

```bash
# Run only Chromium tests
npm run test:chromium

# Run only Firefox tests
npm run test:firefox

# Run only WebKit tests
npm run test:webkit

# Run specific project from config
npx playwright test --project="Mobile Chrome"
npx playwright test --project="Mobile Safari"
```

### Filtering Tests

```bash
# Run tests matching a pattern
npx playwright test login

# Run tests with specific tag
npx playwright test --grep @smoke
npx playwright test --grep @a11y

# Run tests in a specific file
npx playwright test tests/example.spec.ts

# Exclude tests with tag
npx playwright test --grep-invert @slow
```

### Debugging

```bash
# Run in debug mode (step through tests)
npm run test:debug

# Run with Playwright Inspector
PWDEBUG=1 npx playwright test

# Run headed with slow motion
npx playwright test --headed --slow-mo=1000

# Generate test code by recording actions
npm run codegen
```

### Viewing Reports

```bash
# Open HTML report in browser
npm run report

# Or directly
npx playwright show-report
```

---

## Writing Tests

### Basic Test Structure

```typescript
import { test, expect } from '@playwright/test';

test.describe('Feature Name', () => {
  test.beforeEach(async ({ page }) => {
    // Setup before each test
    await page.goto('/');
  });

  test('should do something', async ({ page }) => {
    // Arrange
    const button = page.locator('button[data-testid="submit"]');
    
    // Act
    await button.click();
    
    // Assert
    await expect(page).toHaveURL('/success');
  });
});
```

### Using Tags

```typescript
// Smoke test - runs on PRs
test('critical flow @smoke', async ({ page }) => {
  // Quick critical path validation
});

// Accessibility test
test('page is accessible @a11y', async ({ page }) => {
  // Accessibility checks
});

// Slow test - can be excluded from quick runs
test('complex scenario @slow', async ({ page }) => {
  // Long-running test
});
```

### Working with Locators

```typescript
test('interacting with elements', async ({ page }) => {
  // By test ID (recommended)
  await page.locator('[data-testid="username"]').fill('user@example.com');
  
  // By role (accessible)
  await page.getByRole('button', { name: 'Submit' }).click();
  
  // By text
  await page.getByText('Welcome').isVisible();
  
  // By label
  await page.getByLabel('Email').fill('test@example.com');
  
  // By placeholder
  await page.getByPlaceholder('Enter password').fill('secret');
});
```

### Assertions

```typescript
test('common assertions', async ({ page }) => {
  // Page assertions
  await expect(page).toHaveTitle(/Dashboard/);
  await expect(page).toHaveURL(/\/dashboard/);
  
  // Element assertions
  const element = page.locator('.message');
  await expect(element).toBeVisible();
  await expect(element).toHaveText('Success!');
  await expect(element).toHaveClass(/success/);
  await expect(element).toBeEnabled();
  
  // Count assertions
  const items = page.locator('.list-item');
  await expect(items).toHaveCount(5);
});
```

### API Testing

```typescript
test('API request', async ({ request }) => {
  // GET request
  const response = await request.get('/api/users');
  expect(response.ok()).toBeTruthy();
  
  const users = await response.json();
  expect(users.length).toBeGreaterThan(0);
  
  // POST request
  const createResponse = await request.post('/api/users', {
    data: { name: 'New User', email: 'new@example.com' }
  });
  expect(createResponse.status()).toBe(201);
});
```

---

## Page Object Model

The Page Object Model (POM) pattern encapsulates page interactions for maintainable tests.

### BasePage Class

The included `BasePage.ts` provides common utilities:

```typescript
import { Page, Locator, expect } from '@playwright/test';

export class BasePage {
  protected page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async navigate(path: string = '/') {
    await this.page.goto(path);
    await this.waitForPageLoad();
  }

  async waitForPageLoad() {
    await this.page.waitForLoadState('networkidle');
  }

  async takeScreenshot(name: string) {
    await this.page.screenshot({ 
      path: `screenshots/${name}.png`, 
      fullPage: true 
    });
  }

  // ... more utility methods
}
```

### Creating Page Objects

```typescript
// pages/LoginPage.ts
import { Page, Locator } from '@playwright/test';
import { BasePage } from './BasePage';

export class LoginPage extends BasePage {
  // Locators
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    super(page);
    this.emailInput = page.locator('[data-testid="email"]');
    this.passwordInput = page.locator('[data-testid="password"]');
    this.submitButton = page.locator('button[type="submit"]');
    this.errorMessage = page.locator('.error-message');
  }

  async login(email: string, password: string) {
    await this.navigate('/login');
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }

  async expectError(message: string) {
    await expect(this.errorMessage).toHaveText(message);
  }
}
```

### Using Page Objects in Tests

```typescript
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';

test.describe('Login', () => {
  let loginPage: LoginPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
  });

  test('successful login', async ({ page }) => {
    await loginPage.login('user@example.com', 'password123');
    await expect(page).toHaveURL('/dashboard');
  });

  test('invalid credentials', async () => {
    await loginPage.login('wrong@example.com', 'wrongpass');
    await loginPage.expectError('Invalid credentials');
  });
});
```

### Using Fixtures

Fixtures provide reusable setup for tests:

```typescript
// tests/fixtures/base.ts
import { test as base } from '@playwright/test';
import { LoginPage } from '../../pages/LoginPage';
import { DashboardPage } from '../../pages/DashboardPage';

export const test = base.extend<{
  loginPage: LoginPage;
  dashboardPage: DashboardPage;
  authenticatedPage: Page;
}>({
  loginPage: async ({ page }, use) => {
    await use(new LoginPage(page));
  },
  
  dashboardPage: async ({ page }, use) => {
    await use(new DashboardPage(page));
  },
  
  authenticatedPage: async ({ page }, use) => {
    const loginPage = new LoginPage(page);
    await loginPage.login('test@example.com', 'password');
    await use(page);
  },
});

export { expect } from '@playwright/test';
```

```typescript
// Using fixtures in tests
import { test, expect } from './fixtures/base';

test('dashboard with fixture', async ({ authenticatedPage, dashboardPage }) => {
  await dashboardPage.navigate();
  await expect(dashboardPage.welcomeMessage).toBeVisible();
});
```

---

## CI/CD Integration

### GitHub Actions

The included workflow (`.github/workflows/playwright.yaml`) runs tests on:

- **Push to main**: Full test suite
- **Pull requests**: Smoke tests for quick validation
- **Manual trigger**: On-demand test runs

### Environment Configuration

```yaml
# Override base URL via secrets
env:
  BASE_URL: ${{ secrets.BASE_URL || 'https://staging.example.com' }}
```

### Parallel Execution

Tests run in parallel by default. Configure workers in `playwright.config.ts`:

```typescript
export default defineConfig({
  workers: process.env.CI ? 2 : ${{ values.parallelWorkers }},
  fullyParallel: true,
});
```

### Test Sharding

For large test suites, shard tests across multiple CI jobs:

```yaml
jobs:
  test:
    strategy:
      matrix:
        shard: [1, 2, 3, 4]
    steps:
      - run: npx playwright test --shard=${{ matrix.shard }}/4
```

### Integrating with Other CI Systems

#### GitLab CI

```yaml
playwright:
  image: mcr.microsoft.com/playwright:v1.40.0-jammy
  script:
    - npm ci
    - npx playwright test
  artifacts:
    when: always
    paths:
      - playwright-report/
    expire_in: 1 week
```

#### Azure Pipelines

```yaml
- task: NodeTool@0
  inputs:
    versionSpec: '20.x'
- script: |
    npm ci
    npx playwright install --with-deps
    npx playwright test
  displayName: 'Run Playwright tests'
- publish: playwright-report
  artifact: playwright-report
  condition: always()
```

---

## Troubleshooting

### Browser Installation Issues

**Error: Browser executable not found**

```
Error: Executable doesn't exist at /home/user/.cache/ms-playwright/chromium-xxx/chrome-linux/chrome
```

**Resolution:**

```bash
# Install browsers with system dependencies
npx playwright install --with-deps

# Or install specific browser
npx playwright install chromium --with-deps
```

### Timeout Errors

**Error: Test timeout exceeded**

```
Error: Test timeout of 30000ms exceeded
```

**Resolution:**

1. Increase timeout in config:
   ```typescript
   export default defineConfig({
     timeout: 60000, // 60 seconds
     expect: { timeout: 10000 }, // 10 seconds for assertions
   });
   ```

2. Increase for specific test:
   ```typescript
   test('slow test', async ({ page }) => {
     test.setTimeout(120000); // 2 minutes
     // ...
   });
   ```

### Element Not Found

**Error: Element not found**

```
Error: locator.click: Timeout 30000ms exceeded
```

**Resolution:**

1. Wait for element explicitly:
   ```typescript
   await page.locator('.element').waitFor({ state: 'visible' });
   await page.locator('.element').click();
   ```

2. Use more specific locator:
   ```typescript
   // Instead of
   await page.locator('.button').click();
   
   // Use
   await page.locator('[data-testid="submit-button"]').click();
   ```

### Flaky Tests

**Tests pass locally but fail in CI**

**Resolution:**

1. Add explicit waits:
   ```typescript
   await page.waitForLoadState('networkidle');
   ```

2. Use auto-waiting locators:
   ```typescript
   await expect(page.locator('.result')).toBeVisible();
   ```

3. Increase retries in CI:
   ```typescript
   retries: process.env.CI ? 2 : 0,
   ```

### Authentication Issues

**Tests fail because user is not logged in**

**Resolution:**

Use storage state to persist authentication:

```typescript
// Save auth state after login
await page.context().storageState({ path: 'auth.json' });

// Reuse in other tests
export default defineConfig({
  projects: [
    {
      name: 'authenticated',
      use: { storageState: 'auth.json' },
    },
  ],
});
```

### CI Pipeline Failures

**Tests fail only in GitHub Actions**

**Resolution:**

1. Check for environment differences:
   ```bash
   # Run with same settings as CI
   CI=true npx playwright test
   ```

2. Review artifacts for screenshots/videos

3. Ensure `BASE_URL` is accessible from CI environment

---

## Related Templates

| Template                                                          | Description                             |
| ----------------------------------------------------------------- | --------------------------------------- |
| [test-cypress](/docs/default/template/test-cypress)               | Cypress E2E testing framework           |
| [test-jest](/docs/default/template/test-jest)                     | Jest unit/integration testing           |
| [test-vitest](/docs/default/template/test-vitest)                 | Vitest testing framework                |
| [frontend-react](/docs/default/template/frontend-react)           | React frontend application              |
| [frontend-nextjs](/docs/default/template/frontend-nextjs)         | Next.js application                     |
| [api-node-express](/docs/default/template/api-node-express)       | Node.js Express API                     |

---

## References

- [Playwright Documentation](https://playwright.dev/docs/intro)
- [Playwright API Reference](https://playwright.dev/docs/api/class-playwright)
- [Playwright Best Practices](https://playwright.dev/docs/best-practices)
- [Page Object Model Pattern](https://playwright.dev/docs/pom)
- [Test Fixtures](https://playwright.dev/docs/test-fixtures)
- [GitHub Actions for Playwright](https://playwright.dev/docs/ci-intro)
- [Playwright Test Generator](https://playwright.dev/docs/codegen)
- [Visual Comparisons](https://playwright.dev/docs/test-snapshots)
- [Network Mocking](https://playwright.dev/docs/mock)
