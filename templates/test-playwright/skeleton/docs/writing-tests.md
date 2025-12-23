# Writing Tests

## Test Structure

Tests are organized using Playwright's test runner with describe blocks and test cases:

```typescript
import { test, expect } from '@playwright/test';

test.describe('Feature Name', () => {
  test('should do something', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/Expected Title/);
  });
});
```

## Best Practices

### Use Page Objects

Instead of writing selectors directly in tests, use Page Objects:

```typescript
// Bad
await page.click('[data-testid="submit-button"]');

// Good
await homePage.clickSubmit();
```

### Use Test Fixtures

Create reusable test fixtures for common setup:

```typescript
import { test as base } from '@playwright/test';
import { HomePage } from '../pages/HomePage';

export const test = base.extend<{ homePage: HomePage }>({
  homePage: async ({ page }, use) => {
    const homePage = new HomePage(page);
    await homePage.navigate();
    await use(homePage);
  },
});
```

### Assertions

Use Playwright's built-in assertions:

```typescript
// Element assertions
await expect(page.locator('.title')).toBeVisible();
await expect(page.locator('.count')).toHaveText('5');

// Page assertions
await expect(page).toHaveURL('/dashboard');
await expect(page).toHaveTitle(/Dashboard/);
```

### Test Isolation

Each test runs in isolation with a fresh browser context:

```typescript
test.beforeEach(async ({ page }) => {
  // Runs before each test
  await page.goto('/');
});

test.afterEach(async ({ page }) => {
  // Runs after each test
});
```

## Tagging Tests

Use tags to categorize tests:

```typescript
test('critical flow @smoke', async ({ page }) => {
  // ...
});

test('edge case @regression', async ({ page }) => {
  // ...
});
```

Run tagged tests:
```bash
npx playwright test --grep @smoke
```
