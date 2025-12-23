# Page Object Model

## Overview

The Page Object Model (POM) is a design pattern that creates an abstraction layer between tests and the UI. This improves test maintainability and readability.

## Base Page

All page objects extend the `BasePage` class:

```typescript
import { Page, Locator } from '@playwright/test';

export class BasePage {
  protected page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async navigate(path: string = '/') {
    await this.page.goto(path);
  }

  async waitForPageLoad() {
    await this.page.waitForLoadState('networkidle');
  }
}
```

## Creating a Page Object

1. Create a new file in the `pages/` directory
2. Extend `BasePage`
3. Define locators as properties
4. Add methods for interactions

```typescript
import { Page, Locator, expect } from '@playwright/test';
import { BasePage } from './BasePage';

export class LoginPage extends BasePage {
  // Locators
  readonly usernameInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    super(page);
    this.usernameInput = page.getByTestId('username');
    this.passwordInput = page.getByTestId('password');
    this.submitButton = page.getByRole('button', { name: 'Sign In' });
    this.errorMessage = page.locator('.error-message');
  }

  // Actions
  async login(username: string, password: string) {
    await this.usernameInput.fill(username);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }

  // Assertions
  async expectErrorMessage(message: string) {
    await expect(this.errorMessage).toHaveText(message);
  }
}
```

## Using Page Objects in Tests

```typescript
import { test, expect } from '../fixtures/base';
import { LoginPage } from '../pages/LoginPage';

test.describe('Login', () => {
  test('should login successfully', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.navigate('/login');
    await loginPage.login('user@example.com', 'password123');
    await expect(page).toHaveURL('/dashboard');
  });

  test('should show error for invalid credentials', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.navigate('/login');
    await loginPage.login('invalid@example.com', 'wrong');
    await loginPage.expectErrorMessage('Invalid credentials');
  });
});
```

## Benefits

- **Maintainability**: Selector changes only need updates in one place
- **Readability**: Tests read like user stories
- **Reusability**: Common actions are shared across tests
- **Encapsulation**: Implementation details are hidden from tests
