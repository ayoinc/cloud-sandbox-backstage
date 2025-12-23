import { test as base, expect } from '@playwright/test';
import { BasePage } from '../../pages/BasePage';

/**
 * Extended test fixtures for common page objects and utilities
 */
export const test = base.extend<{
  basePage: BasePage;
}>({
  basePage: async ({ page }, use) => {
    const basePage = new BasePage(page);
    await use(basePage);
  },
});

export { expect };

/**
 * Custom test fixtures can be added here.
 * 
 * Example with authentication:
 * 
 * export const test = base.extend<{
 *   authenticatedPage: Page;
 * }>({
 *   authenticatedPage: async ({ page }, use) => {
 *     await page.goto('/login');
 *     await page.fill('[name="email"]', 'test@example.com');
 *     await page.fill('[name="password"]', 'password');
 *     await page.click('button[type="submit"]');
 *     await page.waitForURL('/dashboard');
 *     await use(page);
 *   },
 * });
 */
